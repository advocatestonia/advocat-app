import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart' show Share;
import 'package:url_launcher/url_launcher.dart';

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
    this.legalUrl,
  });
  final String text;
  final _Severity severity;
  final String? legalRef;
  final String? legalUrl;
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

class _RightsDetailScreenState extends State<RightsDetailScreen>
    with SingleTickerProviderStateMixin {
  final Set<int> _checkedActions = {};
  late final AnimationController _sectionController;

  @override
  void initState() {
    super.initState();
    _sectionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }

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

    // Build sections list for staggered animation
    final sections = <Widget>[];
    var sectionIndex = 0;

    if (scenario.rights.isNotEmpty) {
      sections.add(_AnimatedSection(
        index: sectionIndex++,
        controller: _sectionController,
        child: _ExpandableSection(
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
                  onShare: () => _shareRight(scenario.rights[i].text),
                ),
            ],
          ),
        ),
      ));
    }

    if (scenario.didYouKnow.isNotEmpty) {
      sections.add(_AnimatedSection(
        index: sectionIndex++,
        controller: _sectionController,
        child: _DidYouKnowCard(fact: scenario.didYouKnow.first),
      ));
    }

    if (scenario.obligations.isNotEmpty) {
      sections.add(_AnimatedSection(
        index: sectionIndex++,
        controller: _sectionController,
        child: _ExpandableSection(
          icon: Icons.info_outline,
          iconColor: AppColors.warning,
          title: l10n.youMust.replaceAll(':', ''),
          child: Column(
            children: [
              for (int i = 0; i < scenario.obligations.length; i++)
                _RightItemTile(
                  index: i + 1,
                  item: scenario.obligations[i],
                  onShare: () =>
                      _shareRight(scenario.obligations[i].text),
                ),
            ],
          ),
        ),
      ));
    }

    if (scenario.actions.isNotEmpty) {
      sections.add(_AnimatedSection(
        index: sectionIndex++,
        controller: _sectionController,
        child: _ExpandableSection(
          icon: Icons.bolt_outlined,
          iconColor: AppColors.accent,
          title: l10n.whatToDo,
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
      ));
    }

    if (scenario.didYouKnow.length > 1) {
      sections.add(_AnimatedSection(
        index: sectionIndex++,
        controller: _sectionController,
        child: _DidYouKnowCard(fact: scenario.didYouKnow[1]),
      ));
    }

    if (scenario.deadlines.isNotEmpty) {
      sections.add(_AnimatedSection(
        index: sectionIndex++,
        controller: _sectionController,
        child: _ExpandableSection(
          icon: Icons.schedule_outlined,
          iconColor: AppColors.error,
          title: l10n.deadlines,
          child: Column(
            children: [
              for (final d in scenario.deadlines) _DeadlineTile(item: d),
            ],
          ),
        ),
      ));
    }

    if (scenario.helpContacts.isNotEmpty) {
      sections.add(_AnimatedSection(
        index: sectionIndex++,
        controller: _sectionController,
        child: _ExpandableSection(
          icon: Icons.phone_outlined,
          iconColor: AppColors.success,
          title: l10n.getHelp,
          child: Column(
            children: [
              for (final c in scenario.helpContacts)
                _HelpContactCard(contact: c),
            ],
          ),
        ),
      ));
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
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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
                                      letterSpacing: -0.3,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    scenario.tagline,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white
                                          .withValues(alpha: 0.85),
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
                tooltip: l10n.share,
              ),
            ],
          ),

          // ── Body content ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  ...sections,

                  const SizedBox(height: AppSpacing.lg),

                  // Ask AI CTA button with glow
                  _PremiumCtaButton(
                    onPressed: () => context.push('/chat/general'),
                    label: AppLocalizations.of(context)?.haveQuestionsAi ??
                        'Have questions? Talk to AI',
                    icon: Icons.chat_bubble_outline,
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
    final l10n = AppLocalizations.of(context)!;
    final allRights =
        scenario.rights.map((r) => '- ${r.text}').join('\n');
    final text =
        '${scenario.title}\n\n${scenario.tagline}\n\n${l10n.yourRights.replaceAll(':', '')}\n$allRights\n\n${l10n.sentFromAdvocat}';
    Share.share(text);
  }

  void _shareRight(String rightText) {
    final l10n = AppLocalizations.of(context)!;
    Share.share('$rightText\n\n${l10n.sentFromAdvocat}');
  }

  // ── Build scenario data ────────────────────────────────────────────────
  Map<String, _ScenarioData> _buildData(AppLocalizations l10n) {
    return {
      // ── Domestic Violence & Assault (TOP PRIORITY) ──────────────────
      'domestic-violence': _ScenarioData(
        title: l10n.domesticViolence,
        tagline: l10n.domesticViolenceDesc,
        icon: Icons.health_and_safety_outlined,
        color: AppColors.error,
        rights: [
          _RightItem(l10n.rightCallEmergency,
              severity: _Severity.critical,
              legalRef: 'Emergency Response Centre Act (692/2010)',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/2010/en20100692'),
          _RightItem(l10n.rightVictimProtection,
              severity: _Severity.critical,
              legalRef: 'EU Victims\' Directive 2012/29/EU',
              legalUrl: 'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A32012L0029'),
          _RightItem(l10n.rightRestrainingOrder,
              severity: _Severity.critical,
              legalRef: 'Act on Restraining Orders (898/1998)',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/1998/en19980898'),
          _RightItem(l10n.rightVictimInterpreter,
              severity: _Severity.important,
              legalRef: 'Language Act (423/2003)',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/2003/en20030423'),
          _RightItem(l10n.rightMedicalHelp,
              severity: _Severity.critical,
              legalRef: 'Criminal Code (39/1889) Chapter 21 — Assault § 5',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/1889/en18890039'),
          _RightItem(l10n.rightShelter,
              severity: _Severity.important,
              legalRef: 'Act on Shelter Services (1354/2014)',
              legalUrl: 'https://www.finlex.fi/fi/laki/alkup/2014/20141354'),
        ],
        obligations: [
          _RightItem(l10n.mustReportDanger, severity: _Severity.critical),
          _RightItem(l10n.mustDocumentInjuries, severity: _Severity.important),
        ],
        actions: [
          _ActionItem(l10n.domesticActionCallEmergency),
          _ActionItem(l10n.domesticActionGoToSafe),
          _ActionItem(l10n.domesticActionDocumentEverything),
          _ActionItem(l10n.domesticActionFilePoliceReport),
          _ActionItem(l10n.domesticActionContactShelter),
          _ActionItem(l10n.domesticActionApplyRestraining),
        ],
        deadlines: [
          _DeadlineTile.data(
            l10n.domesticDeadlinePoliceReport,
            isUrgent: false,
          ),
          _DeadlineTile.data(
            l10n.domesticDeadlineRestraining,
            isUrgent: false,
          ),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.domesticFactRestrainingOrder),
          _DidYouKnow(l10n.domesticFactVictimDirective),
        ],
        helpContacts: [
          _HelpContact(
            name: l10n.contactEmergency,
            phone: '112',
          ),
          _HelpContact(
            name: l10n.contactNollaLinja,
            phone: '080 005 005',
            url: 'https://nollalinja.fi/en/',
          ),
          _HelpContact(
            name: l10n.contactShelter,
            phone: '0800 161 323',
            url: 'https://turvakoti.fi',
          ),
          _HelpContact(
            name: l10n.contactCrisisHelpline,
            phone: '09 2525 0111',
          ),
          _HelpContact(
            name: l10n.contactVictimSupportRIKU,
            phone: '116 006',
            url: 'https://www.riku.fi/en/',
          ),
        ],
      ),
      // ── Police Stop ─────────────────────────────────────────────────
      'police-stop': _ScenarioData(
        title: l10n.stoppedByPolice,
        tagline: l10n.stoppedByPoliceDesc,
        icon: Icons.local_police_outlined,
        color: AppColors.info,
        rights: [
          _RightItem(l10n.rightKnowWhyStopped,
              severity: _Severity.critical,
              legalRef: 'Police Act (872/2011) Section 2',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/2011/en20110872'),
          _RightItem(l10n.rightRemainSilent,
              severity: _Severity.critical,
              legalRef: 'Constitution of Finland, Section 21',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/1999/en19990731'),
          _RightItem(l10n.rightAskInterpreter,
              severity: _Severity.important,
              legalRef: 'Language Act (423/2003)',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/2003/en20030423'),
          _RightItem(l10n.rightContactLawyer,
              severity: _Severity.critical,
              legalRef: 'Criminal Procedure Act, Chapter 2',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/1997/en19970689'),
          _RightItem(l10n.rightRecordEncounter, severity: _Severity.info),
        ],
        obligations: [
          _RightItem(l10n.mustProvideName, severity: _Severity.important),
          _RightItem(l10n.mustShowId, severity: _Severity.important),
          _RightItem(l10n.mustNotResist, severity: _Severity.critical),
        ],
        actions: [
          _ActionItem(l10n.policeActionStayCalm),
          _ActionItem(l10n.policeActionAskWhy),
          _ActionItem(l10n.policeActionProvideName),
          _ActionItem(l10n.policeActionWantLawyer),
          _ActionItem(l10n.policeActionAskInterpreter),
          _ActionItem(l10n.policeActionNoteBadge),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.policeFactMustTellReason),
          _DidYouKnow(l10n.policeFactCanRecord),
        ],
        helpContacts: [
          _HelpContact(
            name: l10n.contactFinnishLegalAid,
            phone: '0295 390 390',
            url: 'https://oikeus.fi/oikeusapu/en/',
          ),
          _HelpContact(
            name: l10n.contactNonDiscriminationOmbudsman,
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
              legalRef: 'Aliens Act (301/2004) Section 190',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/2004/en20040301'),
          _RightItem(l10n.rightLegalRep,
              severity: _Severity.critical,
              legalRef: 'Aliens Act Section 9',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/2004/en20040301'),
          _RightItem(l10n.rightInterpreter,
              severity: _Severity.important,
              legalRef: 'Language Act (423/2003)',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/2003/en20030423'),
          _RightItem(l10n.rightStayDuringAppeal,
              severity: _Severity.critical,
              legalRef: 'Aliens Act Section 200',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/2004/en20040301'),
        ],
        actions: [
          _ActionItem(l10n.doNotIgnoreNotice),
          _ActionItem(l10n.noteAppealDeadline),
          _ActionItem(l10n.contactLawyerImmediately),
          _ActionItem(l10n.applyLegalAid),
        ],
        deadlines: [
          _DeadlineTile.data(
            l10n.deportationDeadlineAppeal,
            isUrgent: true,
          ),
          _DeadlineTile.data(
            l10n.deportationDeadlineLegalAid,
            isUrgent: true,
          ),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.deportationFactStayDuringAppeal),
        ],
        helpContacts: [
          _HelpContact(
            name: l10n.contactRefugeeAdviceCentre,
            phone: '09 2313 9300',
            email: 'info@pakolaisneuvonta.fi',
          ),
          _HelpContact(
            name: l10n.contactAdminCourtHelsinki,
            phone: '029 564 2000',
            url: 'https://oikeus.fi/hallintooikeudet/en/',
          ),
          _HelpContact(
            name: l10n.contactFinnishLegalAid,
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
              legalRef: 'Employment Contracts Act (55/2001)',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/2001/en20010055'),
          _RightItem(l10n.workingTimeLimits,
              severity: _Severity.important,
              legalRef: 'Working Time Act (872/2019)',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/2019/en20190872'),
          _RightItem(l10n.annualLeave,
              severity: _Severity.important,
              legalRef: 'Annual Holidays Act (162/2005)',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/2005/en20050162'),
          _RightItem(l10n.sickLeave,
              severity: _Severity.important,
              legalRef: 'Employment Contracts Act Chapter 2, Section 11',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/2001/en20010055'),
          _RightItem(l10n.safeWorkingConditions,
              severity: _Severity.critical,
              legalRef: 'Occupational Safety and Health Act (738/2002)',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/2002/en20020738'),
        ],
        actions: [
          _ActionItem(l10n.workplaceActionKeepContract),
          _ActionItem(l10n.workplaceActionTrackHours),
          _ActionItem(l10n.workplaceActionReportUnsafe),
          _ActionItem(l10n.workplaceActionJoinUnion),
          _ActionItem(l10n.workplaceActionContactAuthority),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.workplaceFactCollectiveWage),
          _DidYouKnow(l10n.workplaceFactOralContract),
        ],
        helpContacts: [
          _HelpContact(
            name: l10n.contactOccupationalSafety,
            phone: '0295 016 620',
            url: 'https://www.tyosuojelu.fi/en',
          ),
          _HelpContact(
            name: l10n.contactTradeUnionSAK,
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
              legalRef: 'Act on Residential Leases (481/1995) Chapter 1',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/1995/en19950481'),
          _RightItem(l10n.securityDeposit,
              severity: _Severity.important,
              legalRef: 'Act on Residential Leases Section 8',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/1995/en19950481'),
          _RightItem(l10n.landlordNotice,
              severity: _Severity.critical,
              legalRef: 'Act on Residential Leases Section 52',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/1995/en19950481'),
          _RightItem(l10n.rightHabitableDwelling,
              severity: _Severity.critical,
              legalRef: 'Act on Residential Leases Section 20',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/1995/en19950481'),
          _RightItem(l10n.protectionUnjustEviction,
              severity: _Severity.critical,
              legalRef: 'Act on Residential Leases Sections 51-55',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/1995/en19950481'),
        ],
        actions: [
          _ActionItem(l10n.tenantActionWrittenAgreement),
          _ActionItem(l10n.tenantActionDocumentCondition),
          _ActionItem(l10n.tenantActionReportMaintenance),
          _ActionItem(l10n.tenantActionNoIllegalEviction),
          _ActionItem(l10n.tenantActionContactAdvisory),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.tenantFactNoEvictionWithoutCourt),
        ],
        helpContacts: [
          _HelpContact(
            name: l10n.contactTenantsAssociation,
            phone: '09 4767 0100',
            url: 'https://vuokralaiset.fi',
          ),
          _HelpContact(
            name: l10n.contactConsumerDisputesBoard,
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
              legalRef: 'Aliens Act Section 123',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/2004/en20040301'),
          _RightItem(l10n.rightContactLawyerDetention,
              severity: _Severity.critical,
              legalRef: 'Constitution of Finland Section 21',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/1999/en19990731'),
          _RightItem(l10n.rightContactEmbassy,
              severity: _Severity.important,
              legalRef: 'Vienna Convention on Consular Relations',
              legalUrl: 'https://legal.un.org/ilc/texts/instruments/english/conventions/9_2_1963.pdf'),
          _RightItem(l10n.rightChallengeDetention,
              severity: _Severity.critical,
              legalRef: 'Aliens Act Section 127',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/2004/en20040301'),
          _RightItem(l10n.rightHumaneTreatment,
              severity: _Severity.critical,
              legalRef: 'ECHR Article 3',
              legalUrl: 'https://www.echr.coe.int/documents/d/echr/convention_ENG'),
        ],
        actions: [
          _ActionItem(l10n.detentionActionAskDecision),
          _ActionItem(l10n.detentionActionRequestLawyer),
          _ActionItem(l10n.detentionActionContactEmbassy),
          _ActionItem(l10n.detentionActionAskMedical),
          _ActionItem(l10n.detentionActionRequestInterpreter),
        ],
        deadlines: [
          _DeadlineTile.data(
            l10n.detentionDeadlineCourtReview,
            isUrgent: true,
          ),
          _DeadlineTile.data(
            l10n.detentionDeadlineContinuation,
            isUrgent: false,
          ),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.detentionFactCourtReview),
        ],
        helpContacts: [
          _HelpContact(
            name: l10n.contactRefugeeAdviceCentre,
            phone: '09 2313 9300',
            email: 'info@pakolaisneuvonta.fi',
          ),
          _HelpContact(
            name: l10n.contactParliamentaryOmbudsman,
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
              legalRef: 'Non-Discrimination Act (1325/2014) Section 19',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/2014/en20141325'),
          _RightItem(l10n.contactLegalAidOffice,
              severity: _Severity.important),
          _RightItem(l10n.reportToPolice,
              severity: _Severity.important,
              legalRef: 'Criminal Code Chapter 11',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/1889/en18890039'),
        ],
        actions: [
          _ActionItem(l10n.discriminationActionWriteDown),
          _ActionItem(l10n.discriminationActionSaveEvidence),
          _ActionItem(l10n.discriminationActionFileComplaint),
          _ActionItem(l10n.discriminationActionContactLegalAid),
          _ActionItem(l10n.discriminationActionReportPolice),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.discriminationFactNonDiscriminationAct),
        ],
        helpContacts: [
          _HelpContact(
            name: l10n.contactNonDiscriminationOmbudsman,
            phone: '0295 666 817',
            email: 'yvv@oikeus.fi',
          ),
          _HelpContact(
            name: l10n.contactVictimSupportRIKU,
            phone: '116 006',
            url: 'https://www.riku.fi/en/',
          ),
        ],
      ),
      // ── Consumer Protection ─────────────────────────────────────────
      'consumer': _ScenarioData(
        title: l10n.consumerProtection,
        tagline: l10n.consumerProtectionDesc,
        icon: Icons.shopping_bag_outlined,
        color: AppColors.accent,
        rights: [
          _RightItem(l10n.rightReturnOnline,
              severity: _Severity.critical,
              legalRef: 'EU Consumer Rights Directive 2011/83/EU',
              legalUrl: 'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A32011L0083'),
          _RightItem(l10n.rightDefectiveProduct,
              severity: _Severity.critical,
              legalRef: 'Consumer Protection Act (38/1978) Chapter 5',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/1978/en19780038'),
          _RightItem(l10n.rightClearPricing,
              severity: _Severity.important,
              legalRef: 'Consumer Protection Act Chapter 2',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/1978/en19780038'),
          _RightItem(l10n.rightComplainBoard,
              severity: _Severity.important,
              legalRef: 'Act on Consumer Disputes Board (8/2007)',
              legalUrl: 'https://www.finlex.fi/fi/laki/ajantasa/2007/20070008'),
          _RightItem(l10n.rightProtectionFraud,
              severity: _Severity.critical,
              legalRef: 'Consumer Protection Act Chapter 2 — Unfair Practices',
              legalUrl: 'https://www.finlex.fi/en/laki/kaannokset/1978/en19780038'),
        ],
        obligations: [
          _RightItem(l10n.mustKeepReceipts, severity: _Severity.important),
          _RightItem(l10n.mustActTimely, severity: _Severity.important),
        ],
        actions: [
          _ActionItem(l10n.consumerActionKeepEvidence),
          _ActionItem(l10n.consumerActionContactSeller),
          _ActionItem(l10n.consumerActionFileComplaint),
          _ActionItem(l10n.consumerActionContactAuthority),
          _ActionItem(l10n.consumerActionReportFraud),
        ],
        deadlines: [
          _DeadlineTile.data(
            l10n.consumerDeadlineWithdrawal,
            isUrgent: true,
          ),
          _DeadlineTile.data(
            l10n.consumerDeadlineDefect,
            isUrgent: false,
          ),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.consumerFactWithdrawal),
          _DidYouKnow(l10n.consumerFactWarranty),
        ],
        helpContacts: [
          _HelpContact(
            name: l10n.contactConsumerAdvisory,
            phone: '029 505 3050',
            url: 'https://www.kkv.fi/en/consumer-advisory-services/',
          ),
          _HelpContact(
            name: l10n.contactConsumerOmbudsman,
            url: 'https://www.kkv.fi/en/consumer-ombudsman/',
          ),
          _HelpContact(
            name: l10n.contactConsumerDisputesBoardDirect,
            phone: '029 566 5200',
            url: 'https://www.kuluttajariita.fi/en/',
          ),
        ],
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Animated section wrapper for staggered entrance
// ---------------------------------------------------------------------------

class _AnimatedSection extends StatelessWidget {
  const _AnimatedSection({
    required this.index,
    required this.controller,
    required this.child,
  });

  final int index;
  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final begin = (index * 0.08).clamp(0.0, 0.6);
    final end = (begin + 0.4).clamp(0.0, 1.0);

    final fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );
    final slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Premium CTA button with glow
// ---------------------------------------------------------------------------

class _PremiumCtaButton extends StatefulWidget {
  const _PremiumCtaButton({
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  @override
  State<_PremiumCtaButton> createState() => _PremiumCtaButtonState();
}

class _PremiumCtaButtonState extends State<_PremiumCtaButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: _pressed ? 0.4 : 0.25),
                blurRadius: _pressed ? 20 : 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
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
// Expandable section widget with enhanced styling
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
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

  String _severityLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.item.severity) {
      case _Severity.critical:
        return l10n.mustKnow;
      case _Severity.important:
        return l10n.important;
      case _Severity.info:
        return l10n.goodToKnow;
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
            boxShadow: [
              BoxShadow(
                color: _severityColor.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
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
                            _severityLabel(context),
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
                    child: const Padding(
                      padding: EdgeInsets.all(4),
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
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: widget.item.legalUrl != null
                        ? () async {
                            final uri = Uri.parse(widget.item.legalUrl!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.item.legalUrl != null
                                ? Icons.open_in_new_outlined
                                : Icons.gavel_outlined,
                            size: 14,
                            color: widget.item.legalUrl != null
                                ? AppColors.info
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              widget.item.legalRef!,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: widget.item.legalUrl != null
                                    ? AppColors.info
                                    : AppColors.textSecondary,
                                decoration: widget.item.legalUrl != null
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                                decorationColor: AppColors.info,
                              ),
                            ),
                          ),
                          if (widget.item.legalUrl != null)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.launch_outlined,
                                size: 12,
                                color: AppColors.info,
                              ),
                            ),
                        ],
                      ),
                    ),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
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
            boxShadow: [
              if (isChecked)
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
            ],
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
                  boxShadow: isChecked
                      ? [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
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
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
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
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                  Text(
                    AppLocalizations.of(context)!.didYouKnow,
                    style: const TextStyle(
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
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
