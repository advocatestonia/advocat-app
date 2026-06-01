// Pure-Dart regression for the remaining small B2B org models:
// OrgMember, OrgInvitation, OrgBranding. All pure (fromJson + getters).
//
// Notable coverage: OrgMember resolves email/name from BOTH an embedded
// `profiles` join object AND a flattened row; its displayName/initial
// fallback chains drive every member-list avatar. OrgInvitation's
// isExpired/isPending are time-based gates on the accept screen.

import 'package:advocat/features/organization/models/org_branding.dart';
import 'package:advocat/features/organization/models/org_invitation.dart';
import 'package:advocat/features/organization/models/org_member.dart';
import 'package:advocat/features/organization/models/org_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrgMember', () {
    test('reads profile fields from embedded `profiles` join object', () {
      final m = OrgMember.fromJson({
        'id': 'm1',
        'org_id': 'o1',
        'user_id': 'u1',
        'role': 'admin',
        'profiles': {
          'email': 'ann@firm.ee',
          'full_name': 'Ann Aru',
          'avatar_url': 'https://x/a.png',
        },
      });
      expect(m.role, OrgRole.admin);
      expect(m.email, 'ann@firm.ee');
      expect(m.fullName, 'Ann Aru');
      expect(m.avatarUrl, 'https://x/a.png');
    });

    test('reads profile fields from a flattened row (no `profiles` key)', () {
      final m = OrgMember.fromJson({
        'id': 'm2',
        'email': 'bob@firm.ee',
        'full_name': 'Bob',
      });
      expect(m.email, 'bob@firm.ee');
      expect(m.fullName, 'Bob');
    });

    test('displayName fallback: full_name → email local part → "User"', () {
      OrgMember mk(Map<String, dynamic> j) => OrgMember.fromJson(j);
      expect(mk({'full_name': 'Carol Caro', 'email': 'c@x.ee'}).displayName,
          'Carol Caro');
      expect(mk({'full_name': '   ', 'email': 'dave@x.ee'}).displayName, 'dave',
          reason: 'blank full_name falls through to email local part');
      expect(mk({'email': 'eve@x.ee'}).displayName, 'eve');
      expect(mk({'email': ''}).displayName, 'User',
          reason: 'no name, no usable email → "User"');
      expect(mk({'email': '@nolocal.ee'}).displayName, 'User',
          reason: 'email with empty local part (@ at index 0) → "User"');
    });

    test('initial is the upper-cased first non-blank char of displayName', () {
      expect(OrgMember.fromJson({'full_name': 'ann'}).initial, 'A');
      expect(OrgMember.fromJson({'email': ''}).initial, 'U'); // "User"
    });
  });

  group('OrgInvitation', () {
    OrgInvitation mk({
      required Duration expiresIn,
      DateTime? acceptedAt,
    }) =>
        OrgInvitation.fromJson({
          'id': 'i1',
          'org_id': 'o1',
          'email': 'new@firm.ee',
          'role': 'member',
          'invited_by': 'u1',
          'expires_at':
              DateTime.now().add(expiresIn).toIso8601String(),
          if (acceptedAt != null)
            'accepted_at': acceptedAt.toIso8601String(),
        });

    test('isExpired true once past expires_at', () {
      expect(mk(expiresIn: const Duration(days: 3)).isExpired, isFalse);
      expect(mk(expiresIn: const Duration(seconds: -1)).isExpired, isTrue);
    });

    test('isPending: not accepted AND not expired', () {
      expect(mk(expiresIn: const Duration(days: 3)).isPending, isTrue);
      expect(
          mk(expiresIn: const Duration(days: 3), acceptedAt: DateTime.now())
              .isPending,
          isFalse,
          reason: 'already accepted → not pending');
      expect(mk(expiresIn: const Duration(seconds: -1)).isPending, isFalse,
          reason: 'expired → not pending');
    });

    test('missing expires_at defaults to ~7 days out (still pending)', () {
      final inv = OrgInvitation.fromJson({'id': 'i', 'email': 'x@y.z'});
      expect(inv.isExpired, isFalse);
      expect(inv.role, OrgRole.member, reason: 'missing role → member');
    });

    test('inviterName falls back inviter_name → invited_by_name', () {
      expect(
          OrgInvitation.fromJson({'id': 'i', 'invited_by_name': 'Boss'})
              .inviterName,
          'Boss');
    });
  });

  group('OrgBranding', () {
    test('empty() leaves all style fields null (= use defaults)', () {
      final b = OrgBranding.empty('o1');
      expect(b.orgId, 'o1');
      expect(b.logoUrl, isNull);
      expect(b.primaryColor, isNull);
      expect(b.customDomain, isNull);
    });

    test('fromJson maps snake_case fields', () {
      final b = OrgBranding.fromJson({
        'org_id': 'o1',
        'logo_url': 'https://x/logo.png',
        'primary_color': '#0B7A70',
        'custom_domain': 'firm.example.com',
        'custom_domain_status': 'active',
      });
      expect(b.logoUrl, 'https://x/logo.png');
      expect(b.primaryColor, '#0B7A70');
      expect(b.customDomain, 'firm.example.com');
      expect(b.customDomainStatus, 'active');
    });

    test('copyWith overrides only named fields, keeps orgId', () {
      final b = OrgBranding.fromJson({
        'org_id': 'o1',
        'primary_color': '#111111',
        'accent_color': '#222222',
      });
      final c = b.copyWith(primaryColor: '#999999');
      expect(c.orgId, 'o1');
      expect(c.primaryColor, '#999999');
      expect(c.accentColor, '#222222', reason: 'untouched field preserved');
    });
  });
}
