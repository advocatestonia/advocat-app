import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
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
import '../features/case_file/screens/case_file_screen.dart';

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
  static const String checker = '/checker';
  static const String checkerCompany = '/checker/company';
  static const String checkerVehicle = '/checker/vehicle';
  static const String vault = '/vault';
  static const String vaultAdd = '/vault/add';
  static const String rights = '/rights';
  static const String rightsDetail = '/rights/:id';
  static const String legalAid = '/legal-aid';
  static const String aiMemory = '/profile/ai-memory';

  /// Case File — auto-built dossier. Optional `?caseId=` query param scopes
  /// to one case; without it the screen shows the cross-case view.
  static const String caseFile = '/case-file';
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
      // Not logged in → go to login (unless already there)
      if (!isAuth && !isAuthRoute) return AppRoutes.login;
      // Logged in but on auth page → go to home
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
        builder: (context, state) => const LoginScreen(),
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
        path: AppRoutes.caseFile,
        name: 'caseFile',
        builder: (context, state) {
          final caseId = state.uri.queryParameters['caseId'];
          return CaseFileScreen(caseId: caseId);
        },
      ),

      // ── 404 recovery redirects ─────────────────────────────────────
      // QA report 2026-05-03 flagged these dead-end routes:
      //   /profile      → /settings  (profile lives inside settings)
      //   /chat         → /home      (chat needs a caseId; bare path is invalid)
      //   /documents    → /home      (TODO: dedicated documents listing screen)
      //   /case/<id>    → /home      (TODO: alias to /cases/<id> once the
      //                              cases router accepts singular form)
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
        redirect: (context, state) => AppRoutes.home,
      ),
      GoRoute(
        path: '/case/:id',
        name: 'caseSingularRedirect',
        redirect: (context, state) => AppRoutes.home,
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
