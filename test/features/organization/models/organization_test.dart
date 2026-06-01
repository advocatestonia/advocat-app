// Pure-Dart regression for the B2B org models: Organization + OrgPlan +
// OrgStatus + UsageStats parsing. All pure (fromJson mappers + computed
// getters) — no Supabase/Flutter binding needed.
//
// Highest-value coverage: Organization.fromJson resolves `myRole` from THREE
// different backend shapes (nested list join, nested map join, scalar
// `my_role`), and the plan/seat/trial getters gate UI. UsageStats.fromJson
// must survive malformed list entries without throwing.

import 'package:advocat/features/organization/models/organization.dart';
import 'package:advocat/features/organization/models/org_role.dart';
import 'package:advocat/features/organization/models/usage_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrgPlan', () {
    test('fromWire round-trips + unknown/null → starter', () {
      for (final p in OrgPlan.values) {
        expect(OrgPlan.fromWire(p.wire), p);
      }
      expect(OrgPlan.fromWire(null), OrgPlan.starter);
      expect(OrgPlan.fromWire('mega'), OrgPlan.starter);
    });

    test('capability gates: branding/api firm+enterprise, white-label/domain enterprise-only', () {
      expect(OrgPlan.starter.hasBranding, isFalse);
      expect(OrgPlan.starter.hasApiAccess, isFalse);
      expect(OrgPlan.firm.hasBranding, isTrue);
      expect(OrgPlan.firm.hasApiAccess, isTrue);
      expect(OrgPlan.firm.hasWhiteLabel, isFalse);
      expect(OrgPlan.firm.hasCustomDomain, isFalse);
      expect(OrgPlan.enterprise.hasWhiteLabel, isTrue);
      expect(OrgPlan.enterprise.hasCustomDomain, isTrue);
    });

    test('yearly price is monthly*12 with the ~2-months-free discount', () {
      expect(OrgPlan.firm.pricePerSeatYearly,
          closeTo(49.0 * 12 * 0.833, 1e-9));
    });
  });

  group('OrgStatus', () {
    test('fromWire round-trips + unknown/null → trial', () {
      for (final s in OrgStatus.values) {
        expect(OrgStatus.fromWire(s.wire), s);
      }
      expect(OrgStatus.fromWire(null), OrgStatus.trial);
      expect(OrgStatus.fromWire('frozen'), OrgStatus.trial);
    });

    test('isActive only for active + trial', () {
      expect(OrgStatus.active.isActive, isTrue);
      expect(OrgStatus.trial.isActive, isTrue);
      expect(OrgStatus.pastDue.isActive, isFalse);
      expect(OrgStatus.canceled.isActive, isFalse);
      expect(OrgStatus.suspended.isActive, isFalse);
    });
  });

  group('Organization.fromJson — myRole resolution (3 shapes)', () {
    Map<String, dynamic> base() => {
          'id': 'org-1',
          'slug': 'acme',
          'name': 'Acme Legal',
          'legal_name': 'Acme Legal OÜ',
          'country': 'EE',
          'billing_email': 'billing@acme.ee',
          'plan': 'firm',
          'seat_count': 3,
          'seat_limit': 25,
          'status': 'active',
          'created_by': 'u-1',
        };

    test('nested list join (org_members!inner(role))', () {
      final j = base()..['org_members'] = [
        {'role': 'admin'},
      ];
      expect(Organization.fromJson(j).myRole, OrgRole.admin);
    });

    test('nested map join', () {
      final j = base()..['org_members'] = {'role': 'billing'};
      expect(Organization.fromJson(j).myRole, OrgRole.billing);
    });

    test('scalar my_role fallback', () {
      final j = base()..['my_role'] = 'viewer';
      expect(Organization.fromJson(j).myRole, OrgRole.viewer);
    });

    test('no role info → myRole null', () {
      expect(Organization.fromJson(base()).myRole, isNull);
    });

    test('empty list join → myRole null (not crash on .first)', () {
      final j = base()..['org_members'] = <dynamic>[];
      expect(Organization.fromJson(j).myRole, isNull);
    });
  });

  group('Organization — defaults + computed getters', () {
    test('missing optional fields fall back to safe defaults', () {
      final o = Organization.fromJson({'id': 'org-x'});
      expect(o.slug, '');
      expect(o.country, 'EE');
      expect(o.plan, OrgPlan.starter);
      expect(o.seatCount, 0);
      expect(o.seatLimit, 5);
      expect(o.status, OrgStatus.trial);
    });

    test('hasAvailableSeats is strict (< limit)', () {
      Organization mk(int count, int limit) => Organization.fromJson({
            'id': 'o',
            'seat_count': count,
            'seat_limit': limit,
          });
      expect(mk(3, 5).hasAvailableSeats, isTrue);
      expect(mk(5, 5).hasAvailableSeats, isFalse, reason: 'at limit → full');
      expect(mk(6, 5).hasAvailableSeats, isFalse);
    });

    test('trialDaysRemaining null unless on trial with an end date', () {
      final future = DateTime.now().add(const Duration(days: 10));
      final onTrial = Organization.fromJson({
        'id': 'o',
        'status': 'trial',
        'trial_ends_at': future.toIso8601String(),
      });
      expect(onTrial.isOnTrial, isTrue);
      expect(onTrial.trialDaysRemaining, inInclusiveRange(8, 10));

      final active = Organization.fromJson({
        'id': 'o',
        'status': 'active',
        'trial_ends_at': future.toIso8601String(),
      });
      expect(active.trialDaysRemaining, isNull,
          reason: 'not on trial → null even with a trial_ends_at present');

      final trialNoEnd =
          Organization.fromJson({'id': 'o', 'status': 'trial'});
      expect(trialNoEnd.isOnTrial, isFalse);
      expect(trialNoEnd.trialDaysRemaining, isNull);
    });

    test('copyWith overrides only the named fields', () {
      final o = Organization.fromJson(base2());
      final c = o.copyWith(seatCount: 9, status: OrgStatus.pastDue);
      expect(c.seatCount, 9);
      expect(c.status, OrgStatus.pastDue);
      expect(c.name, o.name);
      expect(c.plan, o.plan);
    });
  });

  group('UsageStats.fromJson', () {
    test('empty/missing json → zeros + empty lists, no throw', () {
      final s = UsageStats.fromJson(const {}, UsagePeriod.currentMonth);
      expect(s.messagesSent, 0);
      expect(s.apiCalls, 0);
      expect(s.messagesDelta, 0);
      expect(s.dailyActivity, isEmpty);
      expect(s.perMember, isEmpty);
      expect(s.period, UsagePeriod.currentMonth);
    });

    test('parses scalars + filters malformed list entries silently', () {
      final s = UsageStats.fromJson({
        'messages_sent': 42,
        'documents_uploaded': 7,
        'cases_created': 3,
        'api_calls': 100,
        'messages_delta': 0.12,
        'daily_activity': [
          {'date': '2026-06-01', 'value': 5},
          'garbage', // non-map junk must be dropped, not crash
          {'date': '2026-06-02', 'value': 8},
        ],
        'per_member': [
          {'user_id': 'u1', 'display_name': 'Ann', 'messages': 10,
            'documents': 2, 'cases': 1},
        ],
      }, UsagePeriod.last30Days);
      expect(s.messagesSent, 42);
      expect(s.apiCalls, 100);
      expect(s.messagesDelta, closeTo(0.12, 1e-9));
      expect(s.dailyActivity.length, 2,
          reason: 'the "garbage" string entry is filtered out');
      expect(s.dailyActivity.first.value, 5.0);
      expect(s.perMember.single.displayName, 'Ann');
    });

    test('MemberUsage falls back display_name → email → "User"', () {
      expect(MemberUsage.fromJson(const {'email': 'x@y.z'}).displayName,
          'x@y.z');
      expect(MemberUsage.fromJson(const {}).displayName, 'User');
    });
  });
}

Map<String, dynamic> base2() => {
      'id': 'org-2',
      'slug': 'beta',
      'name': 'Beta Firm',
      'legal_name': 'Beta OÜ',
      'country': 'FI',
      'billing_email': 'b@beta.fi',
      'plan': 'enterprise',
      'seat_count': 12,
      'seat_limit': 100000,
      'status': 'active',
      'created_by': 'u-2',
    };
