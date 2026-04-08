import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/case_model.dart';

// ---------------------------------------------------------------------------
// CaseType extensions
// ---------------------------------------------------------------------------

extension CaseTypeX on CaseType {
  /// Human-readable label for the case type.
  String get label {
    switch (this) {
      case CaseType.deportation:
        return 'Deportation';
      case CaseType.asylum:
        return 'Asylum';
      case CaseType.residencePermit:
        return 'Residence Permit';
      case CaseType.familyReunification:
        return 'Family Reunification';
      case CaseType.citizenship:
        return 'Citizenship';
      case CaseType.workPermit:
        return 'Work Permit';
      case CaseType.laborDispute:
        return 'Labor Dispute';
      case CaseType.tenantRights:
        return 'Tenant Rights';
      case CaseType.debtCollection:
        return 'Debt Collection';
      case CaseType.discrimination:
        return 'Discrimination';
      case CaseType.policeMisconduct:
        return 'Police Misconduct';
      case CaseType.socialBenefits:
        return 'Social Benefits';
      case CaseType.domesticViolence:
        return 'Domestic Violence';
      case CaseType.consumerProtection:
        return 'Consumer Protection';
      case CaseType.other:
        return 'Other';
    }
  }

  /// Accent color used for the left bar and type badge.
  Color get accentColor {
    switch (this) {
      case CaseType.deportation:
        return AppColors.error;
      case CaseType.asylum:
        return AppColors.warning;
      case CaseType.residencePermit:
        return AppColors.info;
      case CaseType.familyReunification:
        return AppColors.accent;
      case CaseType.citizenship:
        return AppColors.primary;
      case CaseType.workPermit:
        return AppColors.accentDark;
      case CaseType.laborDispute:
        return AppColors.warning;
      case CaseType.tenantRights:
        return AppColors.info;
      case CaseType.debtCollection:
        return AppColors.error;
      case CaseType.discrimination:
        return AppColors.error;
      case CaseType.policeMisconduct:
        return AppColors.error;
      case CaseType.socialBenefits:
        return AppColors.success;
      case CaseType.domesticViolence:
        return AppColors.error;
      case CaseType.consumerProtection:
        return AppColors.info;
      case CaseType.other:
        return AppColors.textTertiary;
    }
  }
}

// ---------------------------------------------------------------------------
// CaseStatus extensions
// ---------------------------------------------------------------------------

extension CaseStatusX on CaseStatus {
  /// Human-readable label for the status.
  String get label {
    switch (this) {
      case CaseStatus.active:
        return 'Active';
      case CaseStatus.pendingDecision:
        return 'Pending';
      case CaseStatus.appealFiled:
        return 'Appeal Filed';
      case CaseStatus.inCourt:
        return 'In Court';
      case CaseStatus.resolved:
        return 'Resolved';
      case CaseStatus.closed:
        return 'Closed';
    }
  }

  /// Short label for compact display (e.g. app bar chip).
  String get shortLabel {
    switch (this) {
      case CaseStatus.active:
        return 'Active';
      case CaseStatus.pendingDecision:
        return 'Pending';
      case CaseStatus.appealFiled:
        return 'Appeal';
      case CaseStatus.inCourt:
        return 'Court';
      case CaseStatus.resolved:
        return 'Done';
      case CaseStatus.closed:
        return 'Closed';
    }
  }

  /// Semantic color for this status.
  Color get color {
    switch (this) {
      case CaseStatus.active:
        return AppColors.accent;
      case CaseStatus.pendingDecision:
        return AppColors.warning;
      case CaseStatus.appealFiled:
        return AppColors.info;
      case CaseStatus.inCourt:
        return AppColors.primary;
      case CaseStatus.resolved:
        return AppColors.success;
      case CaseStatus.closed:
        return AppColors.textTertiary;
    }
  }
}
