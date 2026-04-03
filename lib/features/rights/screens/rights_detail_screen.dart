import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Severity levels for color-coding rights items
// ---------------------------------------------------------------------------
enum _Severity { critical, important, info }

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class _RightItem {
  const _RightItem(
    this.text, {
    this.severity = _Severity.info,
    this.legalRef,
  });
  final String text;
  final _Severity severity;
  final String? legalRef;
}

class _ActionItem {
  const _ActionItem(this.text);
  final String text;
}

class _DeadlineItem {
  const _DeadlineItem(this.text, {this.isUrgent = false});
  final String text;
  final bool isUrgent;
}

class _HelpContact {
  const _HelpContact({
    required this.name,
    this.phone,
    this.email,
    this.url,
  });
  final String name;
  final String? phone;
  final String? email;
  final String? url;
}

class _DidYouKnow {
  const _DidYouKnow(this.text);
  final String text;
}

class _ScenarioData {
  const _ScenarioData({
    required this.title,
    required this.tagline,
    required this.icon,
    required this.color,
    this.rights = const [],
    this.obligations = const [],
    this.actions = const [],
    this.deadlines = const [],
    this.helpContacts = const [],
    this.didYouKnow = const [],
  });
  final String title;
  final String tagline;
  final IconData icon;
  final Color color;
  final List<_RightItem> rights;
  final List<_RightItem> obligations;
  final List<_ActionItem> actions;
  final List<_DeadlineItem> deadlines;
  final List<_HelpContact> helpContacts;
  final List<_DidYouKnow> didYouKnow;
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

class RightsDetailScreen extends StatefulWidget {
  const RightsDetailScreen({super.key, required this.scenarioId});

  final String scenarioId;

  @override
  State<RightsDetailScreen> createState() => _RightsDetailScreenState();
}

class _RightsDetailScreenState extends State<RightsDetailScreen> {
  final Set<int> _checkedActions = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = _buildData(l10n);
    final scenario = data[widget.scenarioId];

    if (scenario == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.scenarioNotFound)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Visual header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: scenario.color,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scenario.color,
                      scenario.color.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xxl + 16,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                              child: Icon(
                                scenario.icon,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scenario.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    scenario.tagline,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              titlePadding: EdgeInsets.zero,
              title: const SizedBox.shrink(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _shareScenario(scenario),
                tooltip: 'Share',
              ),
            ],
          ),

          // ── Body content ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Your Rights section
                  if (scenario.rights.isNotEmpty)
                    _ExpandableSection(
                      icon: Icons.shield_outlined,
                      iconColor: AppColors.info,
                      title: l10n.yourRights.replaceAll(':', ''),
                      initiallyExpanded: true,
                      child: Column(
                        children: [
                          for (int i = 0; i < scenario.rights.length; i++)
                            _RightItemTile(
                              index: i + 1,
                              item: scenario.rights[i],
                              onShare: () =>
                                  _shareRight(scenario.rights[i].text),
                            ),
                        ],
                      ),
                    ),

                  // "Did you know?" card between sections
                  if (scenario.didYouKnow.isNotEmpty)
                    _DidYouKnowCard(fact: scenario.didYouKnow.first),

                  // Obligations section
                  if (scenario.obligations.isNotEmpty)
                    _ExpandableSection(
                      icon: Icons.info_outline,
                      iconColor: AppColors.warning,
                      title: l10n.youMust.replaceAll(':', ''),
                      child: Column(
                        children: [
                          for (int i = 0;
                              i < scenario.obligations.length;
                              i++)
                            _RightItemTile(
                              index: i + 1,
                              item: scenario.obligations[i],
                              onShare: () => _shareRight(
                                  scenario.obligations[i].text),
                            ),
                        ],
                      ),
                    ),

                  // What To Do - interactive checklist
                  if (scenario.actions.isNotEmpty)
                    _ExpandableSection(
                      icon: Icons.bolt_outlined,
                      iconColor: AppColors.accent,
                      title: 'What To Do',
                      initiallyExpanded: true,
                      child: Column(
                        children: [
                          for (int i = 0; i < scenario.actions.length; i++)
                            _ActionChecklistItem(
                              index: i + 1,
                              text: scenario.actions[i].text,
                              isChecked: _checkedActions.contains(i),
                              onToggle: () {
                                setState(() {
                                  if (_checkedActions.contains(i)) {
                                    _checkedActions.remove(i);
                                  } else {
                                    _checkedActions.add(i);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ),

                  // Second "Did you know?" if available
                  if (scenario.didYouKnow.length > 1)
                    _DidYouKnowCard(fact: scenario.didYouKnow[1]),

                  // Deadlines section
                  if (scenario.deadlines.isNotEmpty)
                    _ExpandableSection(
                      icon: Icons.schedule_outlined,
                      iconColor: AppColors.error,
                      title: 'Deadlines',
                      child: Column(
                        children: [
                          for (final d in scenario.deadlines)
                            _DeadlineTile(item: d),
                        ],
                      ),
                    ),

                  // Get Help section
                  if (scenario.helpContacts.isNotEmpty)
                    _ExpandableSection(
                      icon: Icons.phone_outlined,
                      iconColor: AppColors.success,
                      title: 'Get Help',
                      child: Column(
                        children: [
                          for (final c in scenario.helpContacts)
                            _HelpContactCard(contact: c),
                        ],
                      ),
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  // Ask AI CTA button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.push('/chat/general'),
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                      label: const Text('Have questions? Talk to AI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareScenario(_ScenarioData scenario) {
    final allRights =
        scenario.rights.map((r) => '- ${r.text}').join('\n');
    final text =
        '${scenario.title}\n\n${scenario.tagline}\n\nYour Rights:\n$allRights\n\nSent from Advocat app';
    Share.share(text);
  }

  void _shareRight(String rightText) {
    Share.share('$rightText\n\nSent from Advocat app');
  }

  // ── Build scenario data ────────────────────────────────────────────────
  Map<String, _ScenarioData> _buildData(AppLocalizations l10n) {
    return {
      'police-stop': _ScenarioData(
        title: l10n.stoppedByPolice,
        tagline: l10n.stoppedByPoliceDesc,
        icon: Icons.local_police_outlined,
        color: AppColors.info,
        rights: [
          _RightItem(l10n.rightKnowWhyStopped,
              severity: _Severity.critical,
              legalRef: 'Police Act (872/2011) Section 2'),
          _RightItem(l10n.rightRemainSilent,
              severity: _Severity.critical,
              legalRef: 'Constitution of Finland, Section 21'),
          _RightItem(l10n.rightAskInterpreter,
              severity: _Severity.important,
              legalRef: 'Language Act (423/2003)'),
          _RightItem(l10n.rightContactLawyer,
              severity: _Severity.critical,
              legalRef: 'Criminal Procedure Act, Chapter 2'),
          _RightItem(l10n.rightRecordEncounter, severity: _Severity.info),
        ],
        obligations: [
          _RightItem(l10n.mustProvideName, severity: _Severity.important),
          _RightItem(l10n.mustShowId, severity: _Severity.important),
          _RightItem(l10n.mustNotResist, severity: _Severity.critical),
        ],
        actions: [
          _ActionItem('Stay calm and keep your hands visible'),
          _ActionItem('Ask the officer why you are being stopped'),
          _ActionItem('Provide your name and date of birth'),
          _ActionItem('State clearly: "I want a lawyer before any questions"'),
          _ActionItem('If needed, ask for an interpreter'),
          _ActionItem('Note the officer\'s name and badge number'),
        ],
        didYouKnow: [
          _DidYouKnow(
            'In Finland, police must tell you the reason for stopping you. '
            'If they don\'t, you can ask — and they are legally required to explain.',
          ),
          _DidYouKnow(
            'You can record police interactions in public places in Finland. '
            'This is protected under freedom of expression.',
          ),
        ],
        helpContacts: [
          _HelpContact(
            name: 'Finnish Legal Aid',
            phone: '0295 390 390',
            url: 'https://oikeus.fi/oikeusapu/en/',
          ),
          _HelpContact(
            name: 'Non-Discrimination Ombudsman',
            phone: '0295 666 817',
            email: 'yvv@oikeus.fi',
          ),
        ],
      ),
      'deportation': _ScenarioData(
        title: l10n.deportationNotice,
        tagline: l10n.deportationNoticeDesc,
        icon: Icons.flight_takeoff_outlined,
        color: AppColors.error,
        rights: [
          _RightItem(l10n.rightAppealAdmin,
              severity: _Severity.critical,
              legalRef: 'Aliens Act (301/2004) Section 190'),
          _RightItem(l10n.rightLegalRep,
              severity: _Severity.critical,
              legalRef: 'Aliens Act Section 9'),
          _RightItem(l10n.rightInterpreter,
              severity: _Severity.important,
              legalRef: 'Language Act (423/2003)'),
          _RightItem(l10n.rightStayDuringAppeal,
              severity: _Severity.critical,
              legalRef: 'Aliens Act Section 200'),
        ],
        actions: [
          _ActionItem(l10n.doNotIgnoreNotice),
          _ActionItem(l10n.noteAppealDeadline),
          _ActionItem(l10n.contactLawyerImmediately),
          _ActionItem(l10n.applyLegalAid),
        ],
        deadlines: [
          _DeadlineTile.data(
            'Appeal to Administrative Court — usually 30 days from notification',
            isUrgent: true,
          ),
          _DeadlineTile.data(
            'Apply for legal aid — do this IMMEDIATELY',
            isUrgent: true,
          ),
        ],
        didYouKnow: [
          _DidYouKnow(
            'In Finland, you usually have the right to stay in the country '
            'while your appeal is being processed. Deportation cannot happen '
            'during an active appeal in most cases.',
          ),
        ],
        helpContacts: [
          _HelpContact(
            name: 'Finnish Refugee Advice Centre',
            phone: '09 2313 9300',
            email: 'info@pakolaisneuvonta.fi',
          ),
          _HelpContact(
            name: 'Administrative Court Helsinki',
            phone: '029 564 2000',
            url: 'https://oikeus.fi/hallintooikeudet/en/',
          ),
          _HelpContact(
            name: 'Finnish Legal Aid',
            phone: '0295 390 390',
          ),
        ],
      ),
      'workplace': _ScenarioData(
        title: l10n.workplaceRights,
        tagline: l10n.workplaceRightsDesc,
        icon: Icons.work_outline,
        color: AppColors.accent,
        rights: [
          _RightItem(l10n.minimumWage,
              severity: _Severity.critical,
              legalRef: 'Employment Contracts Act (55/2001)'),
          _RightItem(l10n.workingTimeLimits,
              severity: _Severity.important,
              legalRef: 'Working Time Act (872/2019)'),
          _RightItem(l10n.annualLeave,
              severity: _Severity.important,
              legalRef: 'Annual Holidays Act (162/2005)'),
          _RightItem(l10n.sickLeave,
              severity: _Severity.important,
              legalRef: 'Employment Contracts Act Chapter 2, Section 11'),
          _RightItem(l10n.safeWorkingConditions,
              severity: _Severity.critical,
              legalRef: 'Occupational Safety and Health Act (738/2002)'),
        ],
        actions: [
          _ActionItem('Keep copies of your employment contract'),
          _ActionItem('Track your working hours independently'),
          _ActionItem('Report unsafe conditions to occupational safety'),
          _ActionItem('Join a trade union for protection'),
          _ActionItem('Contact the Occupational Safety Authority if needed'),
        ],
        didYouKnow: [
          _DidYouKnow(
            'In Finland, collective agreements set minimum wages by industry — '
            'there is no single national minimum wage. Your employer must follow '
            'the collective agreement for your field.',
          ),
          _DidYouKnow(
            'Even without a written contract, you have full employee rights '
            'in Finland. An oral agreement is equally binding by law.',
          ),
        ],
        helpContacts: [
          _HelpContact(
            name: 'Occupational Safety Authority',
            phone: '0295 016 620',
            url: 'https://www.tyosuojelu.fi/en',
          ),
          _HelpContact(
            name: 'Trade Union Advice (SAK)',
            phone: '020 774 0100',
          ),
        ],
      ),
      'tenant': _ScenarioData(
        title: l10n.tenantRights,
        tagline: l10n.tenantRightsDesc,
        icon: Icons.home_outlined,
        color: AppColors.warning,
        rights: [
          _RightItem(l10n.writtenRentalAgreement,
              severity: _Severity.important,
              legalRef:
                  'Act on Residential Leases (481/1995) Chapter 1'),
          _RightItem(l10n.securityDeposit,
              severity: _Severity.important,
              legalRef:
                  'Act on Residential Leases Section 8'),
          _RightItem(l10n.landlordNotice,
              severity: _Severity.critical,
              legalRef:
                  'Act on Residential Leases Section 52'),
          _RightItem(l10n.rightHabitableDwelling,
              severity: _Severity.critical,
              legalRef:
                  'Act on Residential Leases Section 20'),
          _RightItem(l10n.protectionUnjustEviction,
              severity: _Severity.critical,
              legalRef:
                  'Act on Residential Leases Sections 51-55'),
        ],
        actions: [
          _ActionItem('Always have a written rental agreement'),
          _ActionItem('Document the apartment condition at move-in (photos)'),
          _ActionItem('Report maintenance issues in writing'),
          _ActionItem('Never agree to illegal eviction — courts must decide'),
          _ActionItem('Contact tenant advisory services if disputes arise'),
        ],
        didYouKnow: [
          _DidYouKnow(
            'A landlord in Finland cannot evict you without a court order, '
            'even if your lease has expired. Changing locks or cutting utilities '
            'is illegal.',
          ),
        ],
        helpContacts: [
          _HelpContact(
            name: 'Finnish Tenants Association',
            phone: '09 4767 0100',
            url: 'https://vuokralaiset.fi',
          ),
          _HelpContact(
            name: 'Consumer Disputes Board',
            phone: '029 566 5200',
          ),
        ],
      ),
      'detention': _ScenarioData(
        title: l10n.immigrationDetention,
        tagline: l10n.immigrationDetentionDesc,
        icon: Icons.lock_outline,
        color: AppColors.error,
        rights: [
          _RightItem(l10n.rightKnowDetentionReason,
              severity: _Severity.critical,
              legalRef: 'Aliens Act Section 123'),
          _RightItem(l10n.rightContactLawyerDetention,
              severity: _Severity.critical,
              legalRef: 'Constitution of Finland Section 21'),
          _RightItem(l10n.rightContactEmbassy,
              severity: _Severity.important,
              legalRef: 'Vienna Convention on Consular Relations'),
          _RightItem(l10n.rightChallengeDetention,
              severity: _Severity.critical,
              legalRef: 'Aliens Act Section 127'),
          _RightItem(l10n.rightHumaneTreatment,
              severity: _Severity.critical,
              legalRef: 'ECHR Article 3'),
        ],
        actions: [
          _ActionItem('Ask for the written detention decision immediately'),
          _ActionItem('Request to contact a lawyer'),
          _ActionItem('Contact your embassy or consulate'),
          _ActionItem('Ask for medical attention if needed'),
          _ActionItem('Request an interpreter for all proceedings'),
        ],
        deadlines: [
          _DeadlineTile.data(
            'District Court must review detention within 4 days',
            isUrgent: true,
          ),
          _DeadlineTile.data(
            'Court reviews continuation every 2 weeks',
            isUrgent: false,
          ),
        ],
        didYouKnow: [
          _DidYouKnow(
            'Immigration detention in Finland must be reviewed by a district '
            'court within 4 days. If it is not, the detention becomes unlawful.',
          ),
        ],
        helpContacts: [
          _HelpContact(
            name: 'Finnish Refugee Advice Centre',
            phone: '09 2313 9300',
            email: 'info@pakolaisneuvonta.fi',
          ),
          _HelpContact(
            name: 'Parliamentary Ombudsman',
            phone: '09 4321',
            url: 'https://www.oikeusasiamies.fi/en',
          ),
        ],
      ),
      'discrimination': _ScenarioData(
        title: l10n.discrimination,
        tagline: l10n.discriminationDesc,
        icon: Icons.balance_outlined,
        color: AppColors.primary,
        rights: [
          _RightItem(l10n.documentIncident,
              severity: _Severity.critical),
          _RightItem(l10n.fileComplaintOmbudsman,
              severity: _Severity.critical,
              legalRef: 'Non-Discrimination Act (1325/2014) Section 19'),
          _RightItem(l10n.contactLegalAidOffice,
              severity: _Severity.important),
          _RightItem(l10n.reportToPolice,
              severity: _Severity.important,
              legalRef: 'Criminal Code Chapter 11'),
        ],
        actions: [
          _ActionItem('Write down exactly what happened (date, time, place)'),
          _ActionItem('Save any evidence: messages, emails, witnesses'),
          _ActionItem('File a complaint with the Non-Discrimination Ombudsman'),
          _ActionItem('Contact a legal aid office for free advice'),
          _ActionItem('Report to police if threats or assault were involved'),
        ],
        didYouKnow: [
          _DidYouKnow(
            'Finland\'s Non-Discrimination Act covers discrimination based on '
            'age, origin, nationality, language, religion, health, disability, '
            'sexual orientation, and other personal characteristics.',
          ),
        ],
        helpContacts: [
          _HelpContact(
            name: 'Non-Discrimination Ombudsman',
            phone: '0295 666 817',
            email: 'yvv@oikeus.fi',
          ),
          _HelpContact(
            name: 'Victim Support Finland (RIKU)',
            phone: '116 006',
            url: 'https://www.riku.fi/en/',
          ),
        ],
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Expandable section widget
// ---------------------------------------------------------------------------

class _ExpandableSection extends StatelessWidget {
  const _ExpandableSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            childrenPadding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
            ),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            children: [child],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Right item tile with severity indicator, number, and share
// ---------------------------------------------------------------------------

class _RightItemTile extends StatefulWidget {
  const _RightItemTile({
    required this.index,
    required this.item,
    required this.onShare,
  });

  final int index;
  final _RightItem item;
  final VoidCallback onShare;

  @override
  State<_RightItemTile> createState() => _RightItemTileState();
}

class _RightItemTileState extends State<_RightItemTile> {
  bool _showRef = false;

  Color get _severityColor {
    switch (widget.item.severity) {
      case _Severity.critical:
        return AppColors.error;
      case _Severity.important:
        return AppColors.warning;
      case _Severity.info:
        return AppColors.accent;
    }
  }

  String get _severityLabel {
    switch (widget.item.severity) {
      case _Severity.critical:
        return 'Must know';
      case _Severity.important:
        return 'Important';
      case _Severity.info:
        return 'Good to know';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: widget.item.legalRef != null
            ? () => setState(() => _showRef = !_showRef)
            : null,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          decoration: BoxDecoration(
            color: _severityColor.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border(
              left: BorderSide(color: _severityColor, width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number badge
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _severityColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.index}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _severityColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.text,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Severity tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _severityColor.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            _severityLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _severityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Share button
                  GestureDetector(
                    onTap: widget.onShare,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.share_outlined,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              // Expandable legal reference
              if (_showRef && widget.item.legalRef != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gavel_outlined,
                          size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          widget.item.legalRef!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action checklist item with tappable checkbox
// ---------------------------------------------------------------------------

class _ActionChecklistItem extends StatelessWidget {
  const _ActionChecklistItem({
    required this.index,
    required this.text,
    required this.isChecked,
    required this.onToggle,
  });

  final int index;
  final String text;
  final bool isChecked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () {
          HapticFeedback.lightImpact();
          onToggle();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          decoration: BoxDecoration(
            color: isChecked
                ? AppColors.success.withValues(alpha: 0.06)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isChecked
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              // Step number / check
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isChecked
                      ? AppColors.success
                      : AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: isChecked
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '$index',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isChecked
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                    decoration: isChecked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Deadline tile with urgency colors
// ---------------------------------------------------------------------------

class _DeadlineTile extends StatelessWidget {
  const _DeadlineTile({required this.item});

  final _DeadlineItem item;

  /// Helper factory for building deadline data inline.
  static _DeadlineItem data(String text, {bool isUrgent = false}) {
    return _DeadlineItem(text, isUrgent: isUrgent);
  }

  @override
  Widget build(BuildContext context) {
    final color = item.isUrgent ? AppColors.error : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border(
            left: BorderSide(color: color, width: 3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.isUrgent
                  ? Icons.warning_amber_rounded
                  : Icons.schedule_outlined,
              color: color,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                item.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight:
                      item.isUrgent ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Did you know?" card
// ---------------------------------------------------------------------------

class _DidYouKnowCard extends StatelessWidget {
  const _DidYouKnowCard({required this.fact});

  final _DidYouKnow fact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withValues(alpha: 0.08),
              AppColors.info.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Did you know?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fact.text,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Help contact card
// ---------------------------------------------------------------------------

class _HelpContactCard extends StatelessWidget {
  const _HelpContactCard({required this.contact});

  final _HelpContact contact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (contact.phone != null)
              _ContactRow(
                icon: Icons.phone_outlined,
                text: contact.phone!,
                color: AppColors.success,
              ),
            if (contact.email != null)
              _ContactRow(
                icon: Icons.email_outlined,
                text: contact.email!,
                color: AppColors.info,
              ),
            if (contact.url != null)
              _ContactRow(
                icon: Icons.language_outlined,
                text: contact.url!,
                color: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
