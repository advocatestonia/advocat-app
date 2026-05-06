import 'dart:convert';

import 'package:advocat/features/case_memory/state/intake_wizard_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('IntakeDraft model', () {
    test('round-trips through JSON', () {
      final draft = IntakeDraft(
        jurisdiction: 'FI',
        authorityType: IntakeAuthorityType.police,
        authorityName: 'Itä-Uudenmaan poliisi',
        caseType: IntakeCaseType.criminal,
        userRole: IntakeUserRole.victim,
        opposingSide: 'Suspect',
        witnesses: const ['John', 'Jane'],
        caseNumber: 'R/123/45',
        incidentDate: DateTime.utc(2025, 8, 30),
        deadlines: [
          IntakeDeadline(what: 'Appeal', date: DateTime.utc(2026, 1, 4)),
        ],
        uploadedDocumentIds: const ['doc-1'],
        urgentShortcutTaken: true,
      );
      final json = draft.toJson();
      final back = IntakeDraft.fromJson(Map<String, dynamic>.from(json));
      expect(back.jurisdiction, 'FI');
      expect(back.authorityType, IntakeAuthorityType.police);
      expect(back.authorityName, 'Itä-Uudenmaan poliisi');
      expect(back.caseType, IntakeCaseType.criminal);
      expect(back.userRole, IntakeUserRole.victim);
      expect(back.opposingSide, 'Suspect');
      expect(back.witnesses, ['John', 'Jane']);
      expect(back.caseNumber, 'R/123/45');
      expect(back.incidentDate, DateTime.utc(2025, 8, 30));
      expect(back.deadlines.single.what, 'Appeal');
      expect(back.deadlines.single.date, DateTime.utc(2026, 1, 4));
      expect(back.uploadedDocumentIds, ['doc-1']);
      expect(back.urgentShortcutTaken, isTrue);
    });

    test('fromJson with unknown schema version returns empty draft', () {
      // ignore: prefer_const_literals_to_create_immutables — IntakeDraft.fromJson takes a Map, not const-able.
      final empty = IntakeDraft.fromJson(<String, dynamic>{
        'v': 99,
        'jurisdiction': 'EE',
      });
      expect(empty.jurisdiction, isNull);
      expect(empty.canFinish, isFalse);
    });

    test('canFinish requires step 1 + step 2', () {
      const empty = IntakeDraft();
      expect(empty.canFinish, isFalse);
      final s1 = empty.copyWith(
        jurisdiction: 'EE',
        authorityType: IntakeAuthorityType.court,
      );
      expect(s1.step1Complete, isTrue);
      expect(s1.canFinish, isFalse);
      final s2 = s1.copyWith(caseType: IntakeCaseType.civil);
      expect(s2.canFinish, isTrue);
    });

    test('copyWith can clear nullable fields via sentinel', () {
      final base = IntakeDraft(
        jurisdiction: 'FI',
        incidentDate: DateTime.utc(2025, 1, 1),
      );
      final cleared =
          base.copyWith(jurisdiction: null, incidentDate: null);
      expect(cleared.jurisdiction, isNull);
      expect(cleared.incidentDate, isNull);
    });
  });

  group('IntakeWizardNotifier — persistence', () {
    test('persists fields to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(intakeWizardProvider.notifier);
      await notifier.loaded;

      notifier.update((d) => d.copyWith(
            jurisdiction: 'EE',
            authorityType: IntakeAuthorityType.court,
            caseType: IntakeCaseType.civil,
          ));

      // Allow the fire-and-forget persist to settle.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(kIntakeDraftPrefKey);
      expect(raw, isNotNull);
      final json = jsonDecode(raw!) as Map<String, dynamic>;
      expect(json['jurisdiction'], 'EE');
      expect(json['authority_type'], 'court');
      expect(json['case_type'], 'civil');
    });

    test('rehydrates on init from existing storage', () async {
      // Pre-seed prefs with a serialized draft.
      final stored = const IntakeDraft(
        jurisdiction: 'RU',
        authorityType: IntakeAuthorityType.opposingParty,
        authorityName: 'Counterparty Ltd',
        caseType: IntakeCaseType.civil,
      ).toJson();
      SharedPreferences.setMockInitialValues({
        kIntakeDraftPrefKey: jsonEncode(stored),
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Read the notifier (constructs it) and wait for rehydrate.
      final notifier = container.read(intakeWizardProvider.notifier);
      await notifier.loaded;

      final draft = container.read(intakeWizardProvider);
      expect(draft.jurisdiction, 'RU');
      expect(draft.authorityType, IntakeAuthorityType.opposingParty);
      expect(draft.authorityName, 'Counterparty Ltd');
      expect(draft.caseType, IntakeCaseType.civil);
    });

    test('clearDraft empties storage and state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(intakeWizardProvider.notifier);
      await notifier.loaded;

      notifier.update(
        (d) => d.copyWith(jurisdiction: 'EE', caseType: IntakeCaseType.civil),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await notifier.clearDraft();

      final state = container.read(intakeWizardProvider);
      expect(state.jurisdiction, isNull);
      expect(state.caseType, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kIntakeDraftPrefKey), isNull);
    });
  });
}
