import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class RightsDetailScreen extends StatelessWidget {
  const RightsDetailScreen({super.key, required this.scenarioId});

  final String scenarioId;

  static const _data = <String, _ScenarioData>{
    'police-stop': _ScenarioData(
      title: 'Stopped by Police',
      sections: [
        _Section(heading: 'You have the right to:', items: [
          'Know why you are being stopped',
          'Remain silent (you must identify yourself)',
          'Ask for an interpreter',
          'Contact a lawyer before questioning',
          'Record the encounter (in public places)',
        ]),
        _Section(heading: 'You must:', items: [
          'Provide your name and date of birth',
          'Show ID if you have one',
          'Not physically resist',
        ]),
      ],
    ),
    'deportation': _ScenarioData(
      title: 'Deportation Notice',
      sections: [
        _Section(heading: 'Immediate steps:', items: [
          'Do NOT ignore the notice - deadlines are strict',
          'Note the appeal deadline (usually 30 days)',
          'Contact a lawyer immediately',
          'Apply for legal aid if needed',
        ]),
        _Section(heading: 'Your rights:', items: [
          'Right to appeal to the Administrative Court',
          'Right to legal representation',
          'Right to an interpreter',
          'Right to stay during appeal (in most cases)',
        ]),
      ],
    ),
    'workplace': _ScenarioData(
      title: 'Workplace Rights',
      sections: [
        _Section(heading: 'Basic rights:', items: [
          'Minimum wage as per collective agreement',
          'Working time limits (max 8h/day, 40h/week)',
          'Annual leave (minimum 2 days per month worked)',
          'Sick leave compensation',
          'Safe working conditions',
        ]),
      ],
    ),
    'tenant': _ScenarioData(
      title: 'Tenant Rights',
      sections: [
        _Section(heading: 'Your rights as a tenant:', items: [
          'Written rental agreement required',
          'Security deposit max 3 months rent',
          'Landlord must give notice (3-6 months)',
          'Right to a habitable dwelling',
          'Protection from unjust eviction',
        ]),
      ],
    ),
    'detention': _ScenarioData(
      title: 'Immigration Detention',
      sections: [
        _Section(heading: 'Your rights in detention:', items: [
          'Right to know the reason for detention',
          'Right to contact a lawyer',
          'Right to contact your embassy',
          'Right to challenge detention in court',
          'Right to humane treatment and medical care',
        ]),
      ],
    ),
    'discrimination': _ScenarioData(
      title: 'Discrimination',
      sections: [
        _Section(heading: 'How to act:', items: [
          'Document the incident (date, time, witnesses)',
          'File a complaint with the Non-Discrimination Ombudsman',
          'Contact a legal aid office',
          'Report to police if criminal (threat, assault)',
        ]),
      ],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final data = _data[scenarioId];
    if (data == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Scenario not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(data.title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: data.sections.length,
        itemBuilder: (context, index) {
          final section = data.sections[index];
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
