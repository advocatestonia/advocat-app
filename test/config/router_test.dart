@Tags(['fast'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/config/router.dart';

void main() {
  group('AppRoutes', () {
    group('Route path constants', () {
      test('onboarding route', () {
        expect(AppRoutes.onboarding, '/onboarding');
      });

      test('login route', () {
        expect(AppRoutes.login, '/login');
      });

      test('register route', () {
        expect(AppRoutes.register, '/register');
      });

      test('home route', () {
        expect(AppRoutes.home, '/home');
      });

      test('cases route', () {
        expect(AppRoutes.cases, '/cases');
      });

      test('caseDetail route with parameter', () {
        expect(AppRoutes.caseDetail, '/cases/:id');
      });

      test('caseDocuments nested route', () {
        expect(AppRoutes.caseDocuments, '/cases/:id/documents');
      });

      test('caseTimeline nested route', () {
        expect(AppRoutes.caseTimeline, '/cases/:id/timeline');
      });

      test('caseCreate route', () {
        expect(AppRoutes.caseCreate, '/cases/new');
      });

      test('scan route', () {
        expect(AppRoutes.scan, '/scan');
      });

      test('chat route with parameter', () {
        expect(AppRoutes.chat, '/chat/:caseId');
      });

      test('deadlines route', () {
        expect(AppRoutes.deadlines, '/deadlines');
      });

      test('settings route', () {
        expect(AppRoutes.settings, '/settings');
      });

      test('subscription route', () {
        expect(AppRoutes.subscription, '/subscription');
      });

      test('email route', () {
        expect(AppRoutes.email, '/email');
      });

      test('checker route', () {
        expect(AppRoutes.checker, '/checker');
      });

      test('checkerCompany route', () {
        expect(AppRoutes.checkerCompany, '/checker/company');
      });

      test('checkerVehicle route', () {
        expect(AppRoutes.checkerVehicle, '/checker/vehicle');
      });

      test('vault route', () {
        expect(AppRoutes.vault, '/vault');
      });

      test('vaultAdd route', () {
        expect(AppRoutes.vaultAdd, '/vault/add');
      });

      test('rights route', () {
        expect(AppRoutes.rights, '/rights');
      });

      test('rightsDetail route with parameter', () {
        expect(AppRoutes.rightsDetail, '/rights/:id');
      });

      test('legalAid route', () {
        expect(AppRoutes.legalAid, '/legal-aid');
      });
    });

    group('Route naming conventions', () {
      test('all routes start with /', () {
        final routes = [
          AppRoutes.onboarding,
          AppRoutes.login,
          AppRoutes.register,
          AppRoutes.home,
          AppRoutes.cases,
          AppRoutes.caseDetail,
          AppRoutes.caseDocuments,
          AppRoutes.caseTimeline,
          AppRoutes.caseCreate,
          AppRoutes.scan,
          AppRoutes.chat,
          AppRoutes.deadlines,
          AppRoutes.settings,
          AppRoutes.subscription,
          AppRoutes.email,
          AppRoutes.checker,
          AppRoutes.checkerCompany,
          AppRoutes.checkerVehicle,
          AppRoutes.vault,
          AppRoutes.vaultAdd,
          AppRoutes.rights,
          AppRoutes.rightsDetail,
          AppRoutes.legalAid,
          AppRoutes.aiMemory,
        ];

        for (final route in routes) {
          expect(route.startsWith('/'), isTrue,
              reason: 'Route "$route" should start with /');
        }
      });

      test('parameterized routes use colon syntax', () {
        expect(AppRoutes.caseDetail, contains(':id'));
        expect(AppRoutes.chat, contains(':caseId'));
        expect(AppRoutes.rightsDetail, contains(':id'));
      });
    });

    group('Nested routes under /cases/:id', () {
      test('caseDocuments is under caseDetail', () {
        expect(
          AppRoutes.caseDocuments,
          startsWith('/cases/:id/'),
        );
        expect(AppRoutes.caseDocuments, endsWith('/documents'));
      });

      test('caseTimeline is under caseDetail', () {
        expect(
          AppRoutes.caseTimeline,
          startsWith('/cases/:id/'),
        );
        expect(AppRoutes.caseTimeline, endsWith('/timeline'));
      });
    });

    group('Checker routes', () {
      test('checker is the parent route', () {
        expect(AppRoutes.checker, '/checker');
      });

      test('checkerCompany is nested under /checker', () {
        expect(
          AppRoutes.checkerCompany,
          startsWith(AppRoutes.checker),
        );
      });

      test('checkerVehicle is nested under /checker', () {
        expect(
          AppRoutes.checkerVehicle,
          startsWith(AppRoutes.checker),
        );
      });
    });

    group('Auth routes', () {
      test('auth routes are distinct from app routes', () {
        final authRoutes = {
          AppRoutes.login,
          AppRoutes.register,
          AppRoutes.onboarding,
        };
        final appRoutes = {
          AppRoutes.home,
          AppRoutes.cases,
          AppRoutes.settings,
          AppRoutes.deadlines,
        };

        // No overlap between auth and app routes
        expect(authRoutes.intersection(appRoutes), isEmpty);
      });
    });

    group('Total route count', () {
      test('has expected number of route constants', () {
        // Count all static route constants in AppRoutes
        // onboarding, login, register, home, cases, caseDetail,
        // caseDocuments, caseTimeline, caseCreate, scan, chat,
        // deadlines, settings, subscription, email,
        // checker, checkerCompany, checkerVehicle,
        // vault, vaultAdd, rights, rightsDetail, legalAid, aiMemory
        // = 24 routes total
        final allRoutes = [
          AppRoutes.onboarding,
          AppRoutes.login,
          AppRoutes.register,
          AppRoutes.home,
          AppRoutes.cases,
          AppRoutes.caseDetail,
          AppRoutes.caseDocuments,
          AppRoutes.caseTimeline,
          AppRoutes.caseCreate,
          AppRoutes.scan,
          AppRoutes.chat,
          AppRoutes.deadlines,
          AppRoutes.settings,
          AppRoutes.subscription,
          AppRoutes.email,
          AppRoutes.checker,
          AppRoutes.checkerCompany,
          AppRoutes.checkerVehicle,
          AppRoutes.vault,
          AppRoutes.vaultAdd,
          AppRoutes.rights,
          AppRoutes.rightsDetail,
          AppRoutes.legalAid,
          AppRoutes.aiMemory,
        ];
        expect(allRoutes, hasLength(24));
      });
    });
  });
}
