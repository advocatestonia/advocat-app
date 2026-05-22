import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'feature_flags.dart';
import '../features/auth/providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/cases/screens/cases_list_screen.dart';
import '../features/cases/screens/case_detail_screen.dart';
import '../features/cases/screens/case_documents_screen.dart';
import '../features/cases/screens/case_timeline_screen.dart';
import '../features/cases/screens/case_create_screen.dart';
import '../features/deadlines/screens/deadlines_screen.dart';
import '../features/documents/screens/document_scan_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/subscription_screen.dart';
import '../features/email/screens/email_screen.dart';
// Email Agent D6 — proactive inbox UI (handoff
// 09_INTEGRATION_INTO_ADVOCAT.md). Sits inside the shell route as a top-
// level tab between Cases and Scan; deep-link target for D7 push.
import '../features/inbox/screens/inbox_screen.dart';
import '../features/inbox/screens/inbox_draft_edit_screen.dart';
import '../features/checker/screens/checker_home_screen.dart';
import '../features/checker/screens/company_checker_screen.dart';
import '../features/checker/screens/vehicle_checker_screen.dart';
import '../shared/widgets/main_shell.dart';
import '../features/vault/screens/document_vault_screen.dart';
import '../features/vault/screens/add_vault_document_screen.dart';
import '../features/rights/screens/rights_guide_screen.dart';
import '../features/rights/screens/rights_detail_screen.dart';
import '../features/legal_aid/screens/legal_aid_calculator_screen.dart';
import '../features/profile/screens/ai_memory_screen.dart';
import '../features/referral/screens/referral_screen.dart';
import '../features/referral/screens/referral_landing_screen.dart';
import '../features/lawyer_verification/screens/lawyer_verification_screen.dart';
// Day2-E — "Book a 15-min call with a partner lawyer" + lawyer dashboard.
// Both routes render a "coming soon" placeholder until
// `kLawyerPartnershipEnabled` flips true (set by --dart-define at build).
import '../features/lawyer_partnership/screens/book_lawyer_call_screen.dart';
import '../features/lawyer_partnership/screens/partner_lawyer_dashboard_screen.dart';
import '../features/case_file/screens/case_file_screen.dart';
// Pkg 1.D — new "Мои дела" / Case Memory screens. Live alongside the
// legacy /cases routes; gradually replacing them.
import '../features/case_memory/screens/cases_list_screen.dart'
    as cm_list;
// Pkg 3 — replaces the minimal /cases-v2/new placeholder with the
// 5-step structured-intake wizard.
import '../features/case_memory/screens/intake_wizard/intake_wizard_screen.dart'
    as cm_intake;
import '../features/case_memory/screens/case_detail_screen.dart'
    as cm_detail;
import '../features/case_memory/screens/case_edit_screen.dart' as cm_edit;
// Phase 2 Pkg 4 — Case Workspace replaces the legacy Pkg 1 case-detail
// screen at /cases-v2/:id. Backwards compat: the legacy screen remains
// reachable when the SharedPreferences flag is `false` (Settings rollback
// toggle, removed next release).
import '../features/case_workspace/providers/case_workspace_provider.dart'
    as cw_provider;
import '../features/case_workspace/screens/case_workspace_screen.dart'
    as cw_screen;
// Pkg 9 — Deadline Radar per-case screens.
import '../features/case_memory/screens/case_deadlines_screen.dart'
    as cm_deadlines;
import '../features/case_memory/screens/deadline_edit_screen.dart'
    as cm_deadline_edit;
import '../features/case_memory/data/case_deadline_repository.dart'
    as cm_deadline_repo;
import '../features/case_memory/state/case_deadline_providers.dart'
    as cm_deadline_providers;
import '../features/case_memory/models/case_deadline.dart'
    as cm_deadline_model;
// Sofia Gold Corpus admin (Phase A) — gated on GOLD_REVIEWER_IDS allowlist.
import '../features/admin/gold_review_screen.dart';
// GDPR Art. 28 — Data Processing Agreement review screen, reachable from
// the checkout-gate dialog and from the Privacy Policy screen.
import '../features/legal/screens/dpa_screen.dart';
// GDPR Art. 9 — manage / withdraw sensitive-data consent, reachable from
// Settings → "Sensitive data consent".
import '../features/legal/screens/sensitive_consent_manage_screen.dart';

/// Named route constants to avoid magic strings.
abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String cases = '/cases';
  static const String caseDetail = '/cases/:id';
  static const String caseDocuments = '/cases/:id/documents';
  static const String caseTimeline = '/cases/:id/timeline';
  static const String caseCreate = '/cases/new';
  static const String scan = '/scan';
  static const String chat = '/chat/:caseId';
  static const String deadlines = '/deadlines';
  static const String settings = '/settings';
  static const String subscription = '/subscription';
  static const String email = '/email';
  // Email Agent D6 — Inbox tab. /inbox lands at the top of the list;
  // /inbox/thread/:id is the deep-link target for D7 push notifications;
  // /inbox/draft/:triageId opens the draft editor wrapper around the
  // existing DraftViewerScreen.
  static const String inbox = '/inbox';
  static const String inboxThread = '/inbox/thread/:threadId';
  static const String inboxDraftEdit = '/inbox/draft/:triageId';
  static const String checker = '/checker';
  static const String checkerCompany = '/checker/company';
  static const String checkerVehicle = '/checker/vehicle';
  static const String vault = '/vault';
  static const String vaultAdd = '/vault/add';
  static const String rights = '/rights';
  static const String rightsDetail = '/rights/:id';
  static const String legalAid = '/legal-aid';
  static const String aiMemory = '/profile/ai-memory';

  /// Referral program ("Invite friends"). Reached from Settings and from
  /// the after-Contract-Review CTA chip.
  static const String referral = '/referral';

  /// Public landing for `/r/<code>` invite links. Reachable while
  /// unauthenticated; stashes the code in SharedPreferences so the
  /// register flow can claim it after auth.
  static const String referralLanding = '/r/:code';

  /// Case File — auto-built dossier. Optional `?caseId=` query param scopes
  /// to one case; without it the screen shows the cross-case view.
  static const String caseFile = '/case-file';

  // Pkg 1.D — Case Memory ("Мои дела"). Lives alongside legacy /cases
  // until the legacy deportation-only screen is retired.
  static const String casesV2 = '/cases-v2';
  static const String caseV2New = '/cases-v2/new';
  static const String caseV2Detail = '/cases-v2/:id';
  static const String caseV2Edit = '/cases-v2/:id/edit';

  /// Sofia Gold Corpus review console. Auth-gated server-side; the route
  /// itself is mounted unconditionally so reviewers can deep-link to it.
  static const String adminGoldReview = '/admin/gold-review';

  /// "AI for verified attorneys — free forever" verification form.
  /// Reached from the /lawyers web landing (deep-link) and from Settings.
  static const String lawyerVerification = '/lawyers/verify';

  /// Day2-E — Pro/Premium "book a 15-min call with a partner lawyer".
  /// Optional `?caseId=` query param pre-binds the booking to a case so
  /// the AI brief can include case_facts.
  static const String bookLawyerCall = '/book-lawyer';

  /// Day2-E — partner-lawyer dashboard (upcoming bookings, earnings,
  /// post-call outcome form).
  static const String partnerLawyerDashboard = '/partner-lawyer';

  /// GDPR Art. 28 — Data Processing Agreement review screen. Linked from
  /// the checkout-gate dialog and from the Privacy Policy.
  static const String dpa = '/legal/dpa';

  /// GDPR Art. 9(2)(a) — manage / withdraw special-category consent.
  /// Reached from Settings → Data & Privacy.
  static const String sensitiveConsent = '/legal/sensitive-consent';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuth = ref.read(isAuthenticatedProvider);
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.onboarding;
      // `/r/<code>` invite landings are public — anyone clicking a share
      // link should reach them even when signed out. Match against the
      // top-level path segment so the path-param doesn't break the check.
      final isReferralLanding =
          state.matchedLocation.startsWith('/r/');
      // Referral feature is gated by kReferralEnabled. When OFF, redirect
      // any referral URL away — otherwise users hit promo copy ("first
      // month 50% off") that doesn't reflect current pricing.
      final isReferralRoute = state.matchedLocation == AppRoutes.referral ||
          isReferralLanding;
      if (!kReferralEnabled && isReferralRoute) {
        return isAuth ? AppRoutes.home : AppRoutes.login;
      }
      // Not logged in → go to login (unless already there or on a public
      // referral landing).
      if (!isAuth && !isAuthRoute && !isReferralLanding) {
        return AppRoutes.login;
      }
      // Logged in but on auth page → go to home. Referral landings stay
      // accessible to authed users too (they may share their own link
      // back to themselves while testing).
      if (isAuth && isAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      // ── Auth routes (no shell) ──────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) {
          // FIX-WAVE 6 (2026-05-20): /login?email=... lets the register
          // screen's "already registered" SnackBar deep-link the user
          // here with their email pre-filled.
          final initialEmail = state.uri.queryParameters['email'];
          return LoginScreen(initialEmail: initialEmail);
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Main app shell with bottom navigation ──────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.cases,
            name: 'cases',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CasesListScreen(),
            ),
          ),
          // Email Agent D6 — Inbox tab. Two paths share one screen:
          //   /inbox                — top of the list.
          //   /inbox/thread/:id     — same screen + focusThreadId so the
          //                           D7 push deep link lands the user on
          //                           the correct row.
          GoRoute(
            path: AppRoutes.inbox,
            name: 'inbox',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: InboxScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.inboxThread,
            name: 'inboxThread',
            pageBuilder: (context, state) {
              final tid = state.pathParameters['threadId'];
              return NoTransitionPage(
                child: InboxScreen(focusThreadId: tid),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.deadlines,
            name: 'deadlines',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DeadlinesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),

      // ── Full-screen routes (outside shell) ─────────────────────────
      GoRoute(
        path: AppRoutes.caseCreate,
        name: 'caseCreate',
        builder: (context, state) => const CaseCreateScreen(),
      ),
      GoRoute(
        path: AppRoutes.caseDetail,
        name: 'caseDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CaseDetailScreen(caseId: id);
        },
        routes: [
          GoRoute(
            path: 'documents',
            name: 'caseDocuments',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CaseDocumentsScreen(caseId: id);
            },
          ),
          GoRoute(
            path: 'timeline',
            name: 'caseTimeline',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CaseTimelineScreen(caseId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.scan,
        name: 'scan',
        builder: (context, state) => const DocumentScanScreen(),
      ),

      // ── Pkg 1.D — Case Memory routes (/cases-v2) ──────────────────
      GoRoute(
        path: AppRoutes.casesV2,
        name: 'casesV2',
        builder: (context, state) => const cm_list.CasesListScreen(),
      ),
      GoRoute(
        path: AppRoutes.caseV2New,
        name: 'caseV2New',
        builder: (context, state) => const cm_intake.IntakeWizardScreen(),
      ),
      GoRoute(
        path: AppRoutes.caseV2Detail,
        name: 'caseV2Detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          // Phase 2 Pkg 4 — workspace replaces detail screen by default.
          // Falls back to the legacy screen when the rollback flag is off.
          final flagOn = ProviderScope.containerOf(context, listen: false)
              .read(cw_provider.caseWorkspaceFlagProvider);
          if (!flagOn) {
            return cm_detail.CaseDetailScreen(caseId: id);
          }
          final tabRaw = state.uri.queryParameters['tab'];
          final initialTab = tabRaw == null
              ? null
              : cw_provider.WorkspaceTab.fromQuery(tabRaw);
          return cw_screen.CaseWorkspaceScreen(
            caseId: id,
            initialTab: initialTab,
          );
        },
        routes: [
          GoRoute(
            path: 'edit',
            name: 'caseV2Edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return cm_edit.CaseEditScreen(caseId: id);
            },
          ),
          // Pkg 9 — Deadline Radar per-case routes.
          GoRoute(
            path: 'deadlines',
            name: 'caseV2Deadlines',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return cm_deadlines.CaseDeadlinesScreen(caseId: id);
            },
            routes: [
              GoRoute(
                path: 'new',
                name: 'caseV2DeadlineNew',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return cm_deadline_edit.DeadlineEditScreen(caseId: id);
                },
              ),
              GoRoute(
                path: ':deadlineId/edit',
                name: 'caseV2DeadlineEdit',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final deadlineId =
                      state.pathParameters['deadlineId']!;
                  return _DeadlineEditLoader(
                    caseId: id,
                    deadlineId: deadlineId,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        builder: (context, state) {
          final caseId = state.pathParameters['caseId']!;
          return ChatScreen(caseId: caseId);
        },
      ),
      GoRoute(
        path: AppRoutes.subscription,
        name: 'subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.email,
        name: 'email',
        builder: (context, state) => const EmailScreen(),
      ),
      // Email Agent D6 — full-screen inbox draft editor (outside shell so
      // the bottom-nav bar doesn't compete with the keyboard).
      GoRoute(
        path: AppRoutes.inboxDraftEdit,
        name: 'inboxDraftEdit',
        builder: (context, state) {
          final tid = state.pathParameters['triageId'] ?? '';
          final threadId = state.uri.queryParameters['threadId'];
          final caseId = state.uri.queryParameters['caseId'];
          return InboxDraftEditScreen(
            triageId: tid,
            threadId: threadId,
            caseId: caseId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.checker,
        name: 'checker',
        builder: (context, state) => const CheckerHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkerCompany,
        name: 'checkerCompany',
        builder: (context, state) => const CompanyCheckerScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkerVehicle,
        name: 'checkerVehicle',
        builder: (context, state) => const VehicleCheckerScreen(),
      ),
      GoRoute(
        path: AppRoutes.vault,
        name: 'vault',
        builder: (context, state) => const DocumentVaultScreen(),
      ),
      GoRoute(
        path: AppRoutes.vaultAdd,
        name: 'vaultAdd',
        builder: (context, state) => const AddVaultDocumentScreen(),
      ),
      GoRoute(
        path: AppRoutes.rights,
        name: 'rights',
        builder: (context, state) => const RightsGuideScreen(),
      ),
      GoRoute(
        path: AppRoutes.rightsDetail,
        name: 'rightsDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RightsDetailScreen(scenarioId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.legalAid,
        name: 'legalAid',
        builder: (context, state) => const LegalAidCalculatorScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiMemory,
        name: 'aiMemory',
        builder: (context, state) => const AiMemoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.referral,
        name: 'referral',
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(
        path: AppRoutes.lawyerVerification,
        name: 'lawyerVerification',
        builder: (context, state) => const LawyerVerificationScreen(),
      ),
      // Day2-E — Pro/Premium "Book a lawyer call" + partner dashboard.
      // Both screens gate on kLawyerPartnershipEnabled internally; the
      // routes themselves are always mounted so a deep-link doesn't 404
      // during the flag-off rollout window.
      GoRoute(
        path: AppRoutes.bookLawyerCall,
        name: 'bookLawyerCall',
        builder: (context, state) {
          final caseId = state.uri.queryParameters['caseId'];
          return BookLawyerCallScreen(caseId: caseId);
        },
      ),
      GoRoute(
        path: AppRoutes.partnerLawyerDashboard,
        name: 'partnerLawyerDashboard',
        builder: (context, state) => const PartnerLawyerDashboardScreen(),
      ),
      // Public `/r/<code>` invite landing. Reachable unauthenticated; the
      // redirect logic above has an explicit `/r/` carve-out.
      GoRoute(
        path: AppRoutes.referralLanding,
        name: 'referralLanding',
        builder: (context, state) {
          final code = state.pathParameters['code'] ?? '';
          return ReferralLandingScreen(code: code);
        },
      ),
      GoRoute(
        path: AppRoutes.caseFile,
        name: 'caseFile',
        builder: (context, state) {
          final caseId = state.uri.queryParameters['caseId'];
          return CaseFileScreen(caseId: caseId);
        },
      ),

      // ── GDPR Art. 28 — DPA review screen ───────────────────────────
      GoRoute(
        path: AppRoutes.dpa,
        name: 'dpa',
        builder: (context, state) => const DpaScreen(),
      ),

      // ── GDPR Art. 9 — manage / withdraw sensitive-data consent ─────
      GoRoute(
        path: AppRoutes.sensitiveConsent,
        name: 'sensitiveConsent',
        builder: (context, state) => const SensitiveConsentManageScreen(),
      ),

      // ── Sofia Gold Corpus review (Phase A) ─────────────────────────
      // Client-side display: hidden unless the current user's id is in
      // the GOLD_REVIEWER_IDS compile-time list. Server-side: the
      // gold-review edge function enforces the same allowlist, so even
      // a hand-crafted URL cannot bypass the gate.
      GoRoute(
        path: AppRoutes.adminGoldReview,
        name: 'adminGoldReview',
        builder: (context, state) => const GoldReviewScreen(),
      ),

      // ── 404 recovery redirects ─────────────────────────────────────
      // QA report 2026-05-03 flagged these dead-end routes:
      //   /profile      → /settings  (profile lives inside settings)
      //   /chat         → /home      (chat needs a caseId; bare path is invalid)
      //   /documents    → /cases     (no dedicated documents listing yet)
      //   /case/<id>    → /cases-v2/<id>  (singular alias for /cases router)
      // These give users a graceful destination instead of a bare
      // "Page not found:" message with no recovery affordance.
      GoRoute(
        path: '/profile',
        name: 'profileRedirect',
        redirect: (context, state) => AppRoutes.settings,
      ),
      GoRoute(
        path: '/chat',
        name: 'chatRedirect',
        redirect: (context, state) => AppRoutes.home,
      ),
      GoRoute(
        path: '/documents',
        name: 'documentsRedirect',
        redirect: (context, state) => AppRoutes.cases,
      ),
      GoRoute(
        path: '/case/:id',
        name: 'caseSingularRedirect',
        redirect: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return '/cases-v2/$id';
        },
      ),
    ],
    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context);
      final path = state.matchedLocation;
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n?.error404Title ?? 'Page not found'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text(
                l10n?.error404Body(path) ?? "We couldn't find: $path",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(l10n?.goToHome ?? 'Go to home'),
              ),
            ],
          ),
        ),
      );
    },
  );
});

/// Loads a single CaseDeadline by id and renders the edit form once it
/// arrives. Pkg 9 — used for `/cases-v2/:id/deadlines/:deadlineId/edit`.
class _DeadlineEditLoader extends ConsumerWidget {
  const _DeadlineEditLoader({
    required this.caseId,
    required this.deadlineId,
  });

  final String caseId;
  final String deadlineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(
      cm_deadline_providers.deadlinesProvider(caseId),
    );
    return asyncList.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$e')),
      ),
      data: (deadlines) {
        cm_deadline_model.CaseDeadline? existing;
        for (final d in deadlines) {
          if (d.id == deadlineId) {
            existing = d;
            break;
          }
        }
        if (existing == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Deadline not found')),
          );
        }
        return cm_deadline_edit.DeadlineEditScreen(
          caseId: caseId,
          existing: existing,
        );
      },
    );
  }
}

// Suppress unused import warnings — `cm_deadline_repo` is referenced
// indirectly through providers in tests/overrides.
// ignore: unused_element
typedef _RoutePkg9DeadlineRepoAlias = cm_deadline_repo.CaseDeadlineRepository;
