@Tags(['fast'])
library;

import 'package:advocat/config/theme.dart';
import 'package:advocat/models/case_model.dart';
import 'package:advocat/shared/utils/case_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── CaseTypeX ────────────────────────────────────────────────────────────

  group('CaseTypeX', () {
    group('label', () {
      test('every CaseType has a non-empty label', () {
        for (final type in CaseType.values) {
          expect(type.label, isNotEmpty, reason: '$type should have a label');
        }
      });

      test('deportation label is Deportation', () {
        expect(CaseType.deportation.label, 'Deportation');
      });

      test('asylum label is Asylum', () {
        expect(CaseType.asylum.label, 'Asylum');
      });

      test('residencePermit label is Residence Permit', () {
        expect(CaseType.residencePermit.label, 'Residence Permit');
      });

      test('familyReunification label is Family Reunification', () {
        expect(CaseType.familyReunification.label, 'Family Reunification');
      });

      test('citizenship label is Citizenship', () {
        expect(CaseType.citizenship.label, 'Citizenship');
      });

      test('workPermit label is Work Permit', () {
        expect(CaseType.workPermit.label, 'Work Permit');
      });

      test('laborDispute label is Labor Dispute', () {
        expect(CaseType.laborDispute.label, 'Labor Dispute');
      });

      test('tenantRights label is Tenant Rights', () {
        expect(CaseType.tenantRights.label, 'Tenant Rights');
      });

      test('debtCollection label is Debt Collection', () {
        expect(CaseType.debtCollection.label, 'Debt Collection');
      });

      test('discrimination label is Discrimination', () {
        expect(CaseType.discrimination.label, 'Discrimination');
      });

      test('policeMisconduct label is Police Misconduct', () {
        expect(CaseType.policeMisconduct.label, 'Police Misconduct');
      });

      test('socialBenefits label is Social Benefits', () {
        expect(CaseType.socialBenefits.label, 'Social Benefits');
      });

      test('domesticViolence label is Domestic Violence', () {
        expect(CaseType.domesticViolence.label, 'Domestic Violence');
      });

      test('consumerProtection label is Consumer Protection', () {
        expect(CaseType.consumerProtection.label, 'Consumer Protection');
      });

      test('inheritance label is Inheritance', () {
        expect(CaseType.inheritance.label, 'Inheritance');
      });

      test('other label is Other', () {
        expect(CaseType.other.label, 'Other');
      });
    });

    group('accentColor', () {
      test('every CaseType has a non-null accentColor', () {
        for (final type in CaseType.values) {
          expect(type.accentColor, isNotNull,
              reason: '$type should have an accent color');
        }
      });

      test('deportation uses error color', () {
        expect(CaseType.deportation.accentColor, AppColors.error);
      });

      test('asylum uses warning color', () {
        expect(CaseType.asylum.accentColor, AppColors.warning);
      });

      test('residencePermit uses info color', () {
        expect(CaseType.residencePermit.accentColor, AppColors.info);
      });

      test('familyReunification uses accent color', () {
        expect(CaseType.familyReunification.accentColor, AppColors.accent);
      });

      test('citizenship uses primary color', () {
        expect(CaseType.citizenship.accentColor, AppColors.primary);
      });

      test('workPermit uses accentDark color', () {
        expect(CaseType.workPermit.accentColor, AppColors.accentDark);
      });

      test('socialBenefits uses success color', () {
        expect(CaseType.socialBenefits.accentColor, AppColors.success);
      });

      test('other uses textTertiary color', () {
        expect(CaseType.other.accentColor, AppColors.textTertiary);
      });
    });
  });

  // ── CaseStatusX ──────────────────────────────────────────────────────────

  group('CaseStatusX', () {
    group('label', () {
      test('every CaseStatus has a non-empty label', () {
        for (final status in CaseStatus.values) {
          expect(status.label, isNotEmpty,
              reason: '$status should have a label');
        }
      });

      test('active label is Active', () {
        expect(CaseStatus.active.label, 'Active');
      });

      test('pendingDecision label is Pending', () {
        expect(CaseStatus.pendingDecision.label, 'Pending');
      });

      test('appealFiled label is Appeal Filed', () {
        expect(CaseStatus.appealFiled.label, 'Appeal Filed');
      });

      test('inCourt label is In Court', () {
        expect(CaseStatus.inCourt.label, 'In Court');
      });

      test('resolved label is Resolved', () {
        expect(CaseStatus.resolved.label, 'Resolved');
      });

      test('closed label is Closed', () {
        expect(CaseStatus.closed.label, 'Closed');
      });
    });

    group('shortLabel', () {
      test('every CaseStatus has a non-empty shortLabel', () {
        for (final status in CaseStatus.values) {
          expect(status.shortLabel, isNotEmpty,
              reason: '$status should have a short label');
        }
      });

      test('active shortLabel is Active', () {
        expect(CaseStatus.active.shortLabel, 'Active');
      });

      test('pendingDecision shortLabel is Pending', () {
        expect(CaseStatus.pendingDecision.shortLabel, 'Pending');
      });

      test('appealFiled shortLabel is Appeal', () {
        expect(CaseStatus.appealFiled.shortLabel, 'Appeal');
      });

      test('inCourt shortLabel is Court', () {
        expect(CaseStatus.inCourt.shortLabel, 'Court');
      });

      test('resolved shortLabel is Done', () {
        expect(CaseStatus.resolved.shortLabel, 'Done');
      });

      test('closed shortLabel is Closed', () {
        expect(CaseStatus.closed.shortLabel, 'Closed');
      });
    });

    group('color', () {
      test('every CaseStatus has a non-null color', () {
        for (final status in CaseStatus.values) {
          expect(status.color, isNotNull,
              reason: '$status should have a color');
        }
      });

      test('active uses accent color', () {
        expect(CaseStatus.active.color, AppColors.accent);
      });

      test('pendingDecision uses warning color', () {
        expect(CaseStatus.pendingDecision.color, AppColors.warning);
      });

      test('appealFiled uses info color', () {
        expect(CaseStatus.appealFiled.color, AppColors.info);
      });

      test('inCourt uses primary color', () {
        expect(CaseStatus.inCourt.color, AppColors.primary);
      });

      test('resolved uses success color', () {
        expect(CaseStatus.resolved.color, AppColors.success);
      });

      test('closed uses textTertiary color', () {
        expect(CaseStatus.closed.color, AppColors.textTertiary);
      });
    });
  });

  // ── Enum completeness ──────────────────────────────────────────────────

  group('Enum completeness', () {
    test('CaseType has 16 values', () {
      expect(CaseType.values.length, 16);
    });

    test('CaseStatus has 6 values', () {
      expect(CaseStatus.values.length, 6);
    });
  });
}
