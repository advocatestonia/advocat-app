// =====================================================================
// IntakeWizardState — draft state for the 5-step intake wizard (Pkg 3).
//
// Persists in SharedPreferences under [kIntakeDraftPrefKey] so that
// accidentally closing the app (or a hot-restart in dev) doesn't lose
// the user's progress mid-wizard. Cleared once a real `user_cases`
// row is created (`clearDraft()` on success path) or when the user
// taps the urgent shortcut and we materialize the draft into a real
// case row.
//
// Shape mirrors the wizard's 5 screens. All fields except the bare
// minimum (jurisdiction + case type) are optional — the wizard can
// short-circuit at any step via the urgent button.
//
// Storage shape: a single JSON blob. A simple bump in versioning
// (kIntakeDraftSchemaVersion) is the migration story; if the version
// stored locally does not match, we drop the draft on rehydrate
// instead of trying to read a stale shape.
// =====================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'active_case_provider.dart' show sharedPreferencesProvider;

/// SharedPreferences key for the persisted intake draft. Versioned so
/// we can change the shape later without crashing on old payloads.
const kIntakeDraftPrefKey = 'advocat.intake_draft.v1';

/// Schema version embedded in the persisted JSON. Bump when the
/// [IntakeDraft] shape changes incompatibly.
const kIntakeDraftSchemaVersion = 1;

/// Total step count — used by the host PageView and the step indicator
/// label.
const kIntakeWizardStepCount = 5;

/// Authority types we recognise. Free-text "name" is captured separately.
enum IntakeAuthorityType {
  police,
  court,
  social,
  employer,
  landlord,
  opposingParty,
  other;

  String get dbValue => name;

  static IntakeAuthorityType? fromDb(String? raw) {
    if (raw == null) return null;
    for (final v in IntakeAuthorityType.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

/// Case-type taxonomy — superset of the minimal create screen so users
/// don't get pushed into "other" for common categories.
enum IntakeCaseType {
  criminal,
  civil,
  family,
  admin,
  immigration,
  labor,
  consumer,
  inheritance,
  other;

  String get dbValue => name;

  static IntakeCaseType? fromDb(String? raw) {
    if (raw == null) return null;
    for (final v in IntakeCaseType.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

/// User-role chips on step 3.
enum IntakeUserRole {
  plaintiff,
  defendant,
  victim,
  accused,
  witness,
  family,
  other;

  String get dbValue => name;

  static IntakeUserRole? fromDb(String? raw) {
    if (raw == null) return null;
    for (final v in IntakeUserRole.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

/// Step 4 deadline row — what + when (ISO yyyy-MM-dd).
@immutable
class IntakeDeadline {
  const IntakeDeadline({this.what = '', this.date});

  final String what;
  final DateTime? date;

  IntakeDeadline copyWith({String? what, Object? date = _sentinel}) {
    return IntakeDeadline(
      what: what ?? this.what,
      date: identical(date, _sentinel) ? this.date : date as DateTime?,
    );
  }

  Map<String, dynamic> toJson() => {
        'what': what,
        'date': date == null
            ? null
            : '${date!.year.toString().padLeft(4, '0')}-'
                '${date!.month.toString().padLeft(2, '0')}-'
                '${date!.day.toString().padLeft(2, '0')}',
      };

  factory IntakeDeadline.fromJson(Map<String, dynamic> json) {
    final raw = json['date'] as String?;
    DateTime? parsed;
    if (raw != null && raw.isNotEmpty) {
      final parts = raw.split('-');
      if (parts.length == 3) {
        parsed = DateTime.utc(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    }
    return IntakeDeadline(
      what: (json['what'] as String?) ?? '',
      date: parsed,
    );
  }

  static const _sentinel = Object();
}

/// Full draft state — the typed single source of truth for the wizard.
@immutable
class IntakeDraft {
  const IntakeDraft({
    this.jurisdiction,
    this.authorityType,
    this.authorityName = '',
    this.caseType,
    this.userRole,
    this.opposingSide = '',
    this.witnesses = const [],
    this.caseNumber = '',
    this.incidentDate,
    this.deadlines = const [],
    this.uploadedDocumentIds = const [],
    this.urgentShortcutTaken = false,
  });

  // ── Step 1 ──
  final String? jurisdiction;
  final IntakeAuthorityType? authorityType;
  final String authorityName;

  // ── Step 2 ──
  final IntakeCaseType? caseType;

  // ── Step 3 ──
  final IntakeUserRole? userRole;
  final String opposingSide;
  final List<String> witnesses;

  // ── Step 4 ──
  final String caseNumber;
  final DateTime? incidentDate;
  final List<IntakeDeadline> deadlines;

  // ── Step 5 ──
  final List<String> uploadedDocumentIds;

  // ── Meta ──
  /// True if the user tapped "Урент — спросить сразу". The greeting
  /// service uses this to switch to the urgent template.
  final bool urgentShortcutTaken;

  // ── Validation helpers ────────────────────────────────────────────

  bool get step1Complete =>
      jurisdiction != null &&
      jurisdiction!.isNotEmpty &&
      authorityType != null;

  bool get step2Complete => caseType != null;

  /// Steps 3-5 are entirely optional — we never block progress on them.
  bool get canFinish => step1Complete && step2Complete;

  // ── Persistence ───────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'v': kIntakeDraftSchemaVersion,
        'jurisdiction': jurisdiction,
        'authority_type': authorityType?.dbValue,
        'authority_name': authorityName,
        'case_type': caseType?.dbValue,
        'user_role': userRole?.dbValue,
        'opposing_side': opposingSide,
        'witnesses': witnesses,
        'case_number': caseNumber,
        'incident_date': incidentDate == null
            ? null
            : '${incidentDate!.year.toString().padLeft(4, '0')}-'
                '${incidentDate!.month.toString().padLeft(2, '0')}-'
                '${incidentDate!.day.toString().padLeft(2, '0')}',
        'deadlines': deadlines.map((d) => d.toJson()).toList(),
        'uploaded_document_ids': uploadedDocumentIds,
        'urgent_shortcut_taken': urgentShortcutTaken,
      };

  factory IntakeDraft.fromJson(Map<String, dynamic> json) {
    final v = json['v'];
    if (v is! int || v != kIntakeDraftSchemaVersion) {
      // Stale draft — don't try to read it. Return an empty one and
      // the notifier will clear the storage on the next save.
      return const IntakeDraft();
    }
    DateTime? incident;
    final raw = json['incident_date'] as String?;
    if (raw != null && raw.isNotEmpty) {
      final parts = raw.split('-');
      if (parts.length == 3) {
        incident = DateTime.utc(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    }
    final witnesses = (json['witnesses'] as List?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];
    final deadlines = (json['deadlines'] as List?)
            ?.whereType<Map>()
            .map((m) => IntakeDeadline.fromJson(Map<String, dynamic>.from(m)))
            .toList(growable: false) ??
        const <IntakeDeadline>[];
    final uploaded = (json['uploaded_document_ids'] as List?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];

    return IntakeDraft(
      jurisdiction: json['jurisdiction'] as String?,
      authorityType: IntakeAuthorityType.fromDb(json['authority_type'] as String?),
      authorityName: (json['authority_name'] as String?) ?? '',
      caseType: IntakeCaseType.fromDb(json['case_type'] as String?),
      userRole: IntakeUserRole.fromDb(json['user_role'] as String?),
      opposingSide: (json['opposing_side'] as String?) ?? '',
      witnesses: witnesses,
      caseNumber: (json['case_number'] as String?) ?? '',
      incidentDate: incident,
      deadlines: deadlines,
      uploadedDocumentIds: uploaded,
      urgentShortcutTaken: (json['urgent_shortcut_taken'] as bool?) ?? false,
    );
  }

  // ── copyWith ──────────────────────────────────────────────────────

  IntakeDraft copyWith({
    Object? jurisdiction = _sentinel,
    Object? authorityType = _sentinel,
    String? authorityName,
    Object? caseType = _sentinel,
    Object? userRole = _sentinel,
    String? opposingSide,
    List<String>? witnesses,
    String? caseNumber,
    Object? incidentDate = _sentinel,
    List<IntakeDeadline>? deadlines,
    List<String>? uploadedDocumentIds,
    bool? urgentShortcutTaken,
  }) {
    return IntakeDraft(
      jurisdiction: identical(jurisdiction, _sentinel)
          ? this.jurisdiction
          : jurisdiction as String?,
      authorityType: identical(authorityType, _sentinel)
          ? this.authorityType
          : authorityType as IntakeAuthorityType?,
      authorityName: authorityName ?? this.authorityName,
      caseType: identical(caseType, _sentinel)
          ? this.caseType
          : caseType as IntakeCaseType?,
      userRole: identical(userRole, _sentinel)
          ? this.userRole
          : userRole as IntakeUserRole?,
      opposingSide: opposingSide ?? this.opposingSide,
      witnesses: witnesses ?? this.witnesses,
      caseNumber: caseNumber ?? this.caseNumber,
      incidentDate: identical(incidentDate, _sentinel)
          ? this.incidentDate
          : incidentDate as DateTime?,
      deadlines: deadlines ?? this.deadlines,
      uploadedDocumentIds: uploadedDocumentIds ?? this.uploadedDocumentIds,
      urgentShortcutTaken: urgentShortcutTaken ?? this.urgentShortcutTaken,
    );
  }

  static const _sentinel = Object();
}

/// State notifier — owns the draft, persists changes (debounced
/// fire-and-forget so UI stays responsive), and exposes async
/// `loaded` future for tests.
class IntakeWizardNotifier extends StateNotifier<IntakeDraft> {
  IntakeWizardNotifier(this._ref) : super(const IntakeDraft()) {
    _loaded = _rehydrate();
  }

  final Ref _ref;
  late final Future<void> _loaded;

  /// Resolves once the initial rehydrate from SharedPreferences finishes.
  /// Tests `await ref.read(intakeWizardProvider.notifier).loaded` to
  /// avoid ordering races.
  Future<void> get loaded => _loaded;

  Future<void> _rehydrate() async {
    try {
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      final raw = prefs.getString(kIntakeDraftPrefKey);
      if (raw == null || raw.isEmpty) return;
      final json = jsonDecode(raw);
      if (json is! Map) return;
      final restored = IntakeDraft.fromJson(Map<String, dynamic>.from(json));
      // Don't overwrite an explicit edit that happened while we were loading.
      if (identical(state, const IntakeDraft())) {
        state = restored;
      }
    } catch (_) {
      // Bad JSON / version mismatch — silently drop and start fresh.
    }
  }

  Future<void> _persist(IntakeDraft draft) async {
    try {
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      await prefs.setString(kIntakeDraftPrefKey, jsonEncode(draft.toJson()));
    } catch (_) {
      // Best-effort; the wizard still works without persistence.
    }
  }

  /// Replace the entire draft. Used by tests and the urgent shortcut.
  void update(IntakeDraft Function(IntakeDraft) mut) {
    final next = mut(state);
    state = next;
    // Fire-and-forget. If the caller needs to await, they read
    // `loaded` after a settled pump.
    unawaited(_persist(next));
  }

  /// Wipe the draft from memory and disk. Called after a successful
  /// case create so the next "+" lands the user on a clean wizard.
  Future<void> clearDraft() async {
    state = const IntakeDraft();
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.remove(kIntakeDraftPrefKey);
  }
}

/// Provider — single source of truth for the wizard's draft.
final intakeWizardProvider =
    StateNotifierProvider<IntakeWizardNotifier, IntakeDraft>((ref) {
  return IntakeWizardNotifier(ref);
});
