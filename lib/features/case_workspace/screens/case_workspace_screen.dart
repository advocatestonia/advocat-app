// =====================================================================
// Phase 2 Pkg 4 — Case Workspace screen.
//
// 7-tab Material 3 TabBar host. Tabs in order:
//   Overview / Chat / Timeline / Documents / Deadlines / Drafts / Inbox
//
// Replaces the legacy CaseDetailScreen at `/cases-v2/:id`. Backwards
// compat lives in router.dart — when the feature flag is `false`, the
// router resolves the same path to the legacy detail screen.
//
// Mounting side effects:
//   * Sets activeCaseProvider (so claude-proxy injects this case into
//     the chat system prompt for free).
//   * Initialises the tab selection from `?tab=…` query param OR
//     persisted last-tab key (whichever wins by URL precedence).
//
// Tab change side effects:
//   * Persists the new tab via [workspaceLastTabProvider].
//   * Replaces the URL query param via go_router so deep-linking and
//     in-app share-this-link both round-trip correctly.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../case_memory/models/user_case.dart';
import '../../case_memory/state/active_case_provider.dart';
import '../../case_memory/state/cases_list_provider.dart';
import '../providers/case_workspace_provider.dart';
import '../tabs/chat_tab.dart';
import '../tabs/deadlines_tab.dart';
import '../tabs/documents_tab.dart';
import '../tabs/drafts_tab.dart';
import '../tabs/inbox_tab.dart';
import '../tabs/overview_tab.dart';
import '../tabs/timeline_tab.dart';

/// Threshold for the "centre the TabBar on wide screens" tweak. Below
/// this width we let the tabs scroll horizontally edge-to-edge.
const double _kWideBreakpoint = 900;

class CaseWorkspaceScreen extends ConsumerStatefulWidget {
  const CaseWorkspaceScreen({
    super.key,
    required this.caseId,
    this.initialTab,
  });

  final String caseId;

  /// When provided, overrides the persisted last-tab. Set by the router
  /// from `?tab=…` query param.
  final WorkspaceTab? initialTab;

  @override
  ConsumerState<CaseWorkspaceScreen> createState() =>
      _CaseWorkspaceScreenState();
}

class _CaseWorkspaceScreenState extends ConsumerState<CaseWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  late WorkspaceTab _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialTab ??
        ref.read(workspaceLastTabProvider(widget.caseId));
    _controller = TabController(
      length: WorkspaceTab.values.length,
      vsync: this,
      initialIndex: _selected.index,
    );
    _controller.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant CaseWorkspaceScreen old) {
    super.didUpdateWidget(old);
    if (old.initialTab != widget.initialTab && widget.initialTab != null) {
      _setTab(widget.initialTab!, fromUrl: true);
    }
  }

  void _onTabChanged() {
    if (_controller.indexIsChanging) return;
    final next = WorkspaceTab.values[_controller.index];
    if (next == _selected) return;
    _setTab(next);
  }

  void _setTab(WorkspaceTab next, {bool fromUrl = false}) {
    setState(() => _selected = next);
    if (_controller.index != next.index) {
      _controller.animateTo(next.index);
    }
    // Persist last-tab.
    final notifier =
        ref.read(workspaceLastTabProvider(widget.caseId).notifier);
    notifier.setTab(next);
    // Mirror to URL so back/forward + deep-linking work.
    if (!fromUrl) {
      final router = GoRouter.of(context);
      // Build the new path with ?tab= replacing whatever was there.
      router.go('/cases-v2/${widget.caseId}?tab=${next.name}');
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTabChanged);
    _controller.dispose();
    super.dispose();
  }

  /// Sets the active case in [activeCaseProvider] iff it is not already
  /// set to this case. Called from [build] via a post-frame callback so
  /// it doesn't fight Riverpod's "no notifier writes during build" rule.
  void _maybeSetActiveCase(UserCase c) {
    final active = ref.read(activeCaseProvider).activeCase;
    if (active?.id == c.id) return;
    // ignore: discarded_futures — fire-and-forget; persistence is
    // SharedPreferences-backed and the UI reads the in-memory state
    // synchronously.
    ref.read(activeCaseProvider.notifier).setActiveCase(c);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncCase = ref.watch(caseByIdProvider(widget.caseId));

    return asyncCase.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$e')),
      ),
      data: (c) {
        if (c == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n?.error ?? 'Case not found')),
          );
        }
        // Run the active-case bind once the frame settles.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _maybeSetActiveCase(c);
        });
        return _buildScaffold(context, c, l10n);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    UserCase userCase,
    AppLocalizations? l10n,
  ) {
    final width = MediaQuery.of(context).size.width;
    final centerTabs = width >= _kWideBreakpoint;

    final tabBar = TabBar(
      key: const Key('workspace-tabbar'),
      controller: _controller,
      isScrollable: true,
      tabAlignment:
          centerTabs ? TabAlignment.center : TabAlignment.start,
      tabs: [
        Tab(text: l10n?.workspaceTabOverview ?? 'Overview'),
        Tab(text: l10n?.workspaceTabChat ?? 'Chat'),
        Tab(text: l10n?.timelineSection ?? 'Timeline'),
        Tab(text: l10n?.documents ?? 'Documents'),
        _BadgedTab(
          label: l10n?.deadlines ?? 'Deadlines',
          badgeCount:
              ref.watch(workspaceDeadlineBadgeProvider(userCase.id)),
        ),
        _BadgedTab(
          label: l10n?.workspaceTabDrafts ?? 'Drafts',
          badgeCount:
              ref.watch(workspaceDraftsBadgeProvider(userCase.id)),
        ),
        _BadgedTab(
          label: l10n?.inboxTitle ?? 'Inbox',
          badgeCount:
              ref.watch(workspaceInboxBadgeProvider(userCase.id)),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          userCase.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            key: const Key('workspace-edit-btn'),
            tooltip: l10n?.edit ?? 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push('/cases-v2/${userCase.id}/edit'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: tabBar,
        ),
      ),
      body: TabBarView(
        key: const Key('workspace-tabview'),
        controller: _controller,
        children: [
          OverviewTab(userCase: userCase),
          ChatTab(caseId: userCase.id, caseName: userCase.title),
          TimelineTab(userCase: userCase),
          DocumentsTab(caseId: userCase.id),
          DeadlinesTab(caseId: userCase.id),
          DraftsTab(caseId: userCase.id),
          InboxTab(caseId: userCase.id),
        ],
      ),
    );
  }
}

/// Tab label with an optional rounded count badge on the right.
/// The badge is suppressed when [badgeCount] is 0.
class _BadgedTab extends StatelessWidget {
  const _BadgedTab({required this.label, required this.badgeCount});

  final String label;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    if (badgeCount <= 0) return Tab(text: label);
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badgeCount > 99 ? '99+' : '$badgeCount',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
