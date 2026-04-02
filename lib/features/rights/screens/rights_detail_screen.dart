import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

class RightsDetailScreen extends StatelessWidget {
  const RightsDetailScreen({super.key, required this.scenarioId});

  final String scenarioId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = _buildData(l10n);
    final scenarioData = data[scenarioId];

    if (scenarioData == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.scenarioNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(scenarioData.title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: scenarioData.sections.length,
        itemBuilder: (context, index) {
          final section = scenarioData.sections[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.heading,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.sm),
                ...section.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6, right: 8),
                            child: Icon(Icons.circle,
                                size: 6, color: AppColors.accent),
                          ),
                          Expanded(
                            child: Text(item,
                                style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<String, _ScenarioData> _buildData(AppLocalizations l10n) {
    return {
      'police-stop': _ScenarioData(
        title: l10n.stoppedByPolice,
        sections: [
          _Section(heading: l10n.youHaveRightTo, items: [
            l10n.rightKnowWhyStopped,
            l10n.rightRemainSilent,
            l10n.rightAskInterpreter,
            l10n.rightContactLawyer,
            l10n.rightRecordEncounter,
          ]),
          _Section(heading: l10n.youMust, items: [
            l10n.mustProvideName,
            l10n.mustShowId,
            l10n.mustNotResist,
          ]),
        ],
      ),
      'deportation': _ScenarioData(
        title: l10n.deportationNotice,
        sections: [
          _Section(heading: l10n.immediateSteps, items: [
            l10n.doNotIgnoreNotice,
            l10n.noteAppealDeadline,
            l10n.contactLawyerImmediately,
            l10n.applyLegalAid,
          ]),
          _Section(heading: l10n.yourRights, items: [
            l10n.rightAppealAdmin,
            l10n.rightLegalRep,
            l10n.rightInterpreter,
            l10n.rightStayDuringAppeal,
          ]),
        ],
      ),
      'workplace': _ScenarioData(
        title: l10n.workplaceRights,
        sections: [
          _Section(heading: l10n.basicRights, items: [
            l10n.minimumWage,
            l10n.workingTimeLimits,
            l10n.annualLeave,
            l10n.sickLeave,
            l10n.safeWorkingConditions,
          ]),
        ],
      ),
      'tenant': _ScenarioData(
        title: l10n.tenantRights,
        sections: [
          _Section(heading: l10n.yourRightsAsTenant, items: [
            l10n.writtenRentalAgreement,
            l10n.securityDeposit,
            l10n.landlordNotice,
            l10n.rightHabitableDwelling,
            l10n.protectionUnjustEviction,
          ]),
        ],
      ),
      'detention': _ScenarioData(
        title: l10n.immigrationDetention,
        sections: [
          _Section(heading: l10n.yourRightsInDetention, items: [
            l10n.rightKnowDetentionReason,
            l10n.rightContactLawyerDetention,
            l10n.rightContactEmbassy,
            l10n.rightChallengeDetention,
            l10n.rightHumaneTreatment,
          ]),
        ],
      ),
      'discrimination': _ScenarioData(
        title: l10n.discrimination,
        sections: [
          _Section(heading: l10n.howToAct, items: [
            l10n.documentIncident,
            l10n.fileComplaintOmbudsman,
            l10n.contactLegalAidOffice,
            l10n.reportToPolice,
          ]),
        ],
      ),
    };
  }
}

class _ScenarioData {
  const _ScenarioData({required this.title, required this.sections});
  final String title;
  final List<_Section> sections;
}

class _Section {
  const _Section({required this.heading, required this.items});
  final String heading;
  final List<String> items;
}
