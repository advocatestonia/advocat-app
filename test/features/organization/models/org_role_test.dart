// Pure-Dart regression for OrgRole — the client-side B2B permission matrix.
//
// These getters drive which org actions a user's UI exposes (invite members,
// manage billing/branding/API keys, create content). A wrong `==` would
// silently widen privilege, so the full role × capability matrix is pinned
// here. Server-side RLS is the real authority; this test locks the client's
// view of it so the two can't drift apart unnoticed.

import 'package:advocat/features/organization/models/org_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrgRole.fromWire', () {
    test('round-trips every known wire value', () {
      for (final r in OrgRole.values) {
        expect(OrgRole.fromWire(r.wire), r);
      }
    });

    test('null / unknown → member (fail-safe default, never crash)', () {
      expect(OrgRole.fromWire(null), OrgRole.member);
      expect(OrgRole.fromWire('superadmin'), OrgRole.member);
      expect(OrgRole.fromWire(''), OrgRole.member);
      expect(OrgRole.fromWire('OWNER'), OrgRole.member,
          reason: 'wire match is case-sensitive — "OWNER" != "owner"');
    });
  });

  group('permission matrix', () {
    // Expected capability table — the single source of truth for this test.
    // [canManageMembers, canManageBilling, canManageBranding,
    //  canManageApiKeys, canCreate, isReadOnly]
    const matrix = <OrgRole, List<bool>>{
      OrgRole.owner: [true, true, true, true, true, false],
      OrgRole.admin: [true, true, true, true, true, false],
      OrgRole.billing: [false, true, false, false, false, false],
      OrgRole.member: [false, false, false, false, true, false],
      OrgRole.viewer: [false, false, false, false, false, true],
    };

    test('every role matches its expected capability row', () {
      matrix.forEach((role, caps) {
        expect(role.canManageMembers, caps[0], reason: '$role canManageMembers');
        expect(role.canManageBilling, caps[1], reason: '$role canManageBilling');
        expect(role.canManageBranding, caps[2], reason: '$role canManageBranding');
        expect(role.canManageApiKeys, caps[3], reason: '$role canManageApiKeys');
        expect(role.canCreate, caps[4], reason: '$role canCreate');
        expect(role.isReadOnly, caps[5], reason: '$role isReadOnly');
      });
    });

    test('the matrix covers every defined role (no role left unpinned)', () {
      expect(matrix.keys.toSet(), OrgRole.values.toSet());
    });
  });

  group('privilege invariants', () {
    test('only owner/admin manage members, branding, API keys', () {
      for (final r in OrgRole.values) {
        final privileged = r == OrgRole.owner || r == OrgRole.admin;
        expect(r.canManageMembers, privileged);
        expect(r.canManageBranding, privileged);
        expect(r.canManageApiKeys, privileged);
      }
    });

    test('billing can manage billing but cannot create content', () {
      expect(OrgRole.billing.canManageBilling, isTrue);
      expect(OrgRole.billing.canCreate, isFalse,
          reason: 'billing is read-only except for billing screens');
    });

    test('viewer is the only read-only role and can do nothing else', () {
      expect(OrgRole.viewer.isReadOnly, isTrue);
      expect(OrgRole.viewer.canCreate, isFalse);
      expect(OrgRole.viewer.canManageMembers, isFalse);
      expect(OrgRole.viewer.canManageBilling, isFalse);
      for (final r in OrgRole.values) {
        if (r != OrgRole.viewer) expect(r.isReadOnly, isFalse);
      }
    });
  });
}
