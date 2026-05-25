import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/api_key.dart';
import '../models/org_branding.dart';
import '../models/org_invitation.dart';
import '../models/org_member.dart';
import '../models/org_role.dart';
import '../models/organization.dart';
import '../models/usage_stats.dart';

/// Riverpod provider for the B2B repository — every UI layer talks to
/// Supabase through this single seam so we can mock it in widget tests.
final orgRepositoryProvider = Provider<OrgRepository>((ref) {
  return SupabaseOrgRepository();
});

/// All B2B data access — Supabase tables + edge functions.
///
/// The interface is intentionally narrow: each method returns a typed
/// model or throws an [OrgRepositoryException] with a localized-friendly
/// message key. The provider layer turns exceptions into snackbars.
abstract class OrgRepository {
  Future<List<Organization>> listMyOrgs();
  Future<Organization?> getOrgBySlug(String slug);
  Future<bool> isSlugAvailable(String slug);
  Future<Organization> createOrganization({
    required String name,
    required String slug,
    required String legalName,
    required String country,
    required String billingEmail,
    String? vatId,
    required OrgPlan plan,
    required bool yearly,
  });

  // Members.
  Future<List<OrgMember>> listMembers(String orgId);
  Future<List<OrgInvitation>> listPendingInvitations(String orgId);
  Future<void> inviteMember({
    required String orgId,
    required String email,
    required OrgRole role,
    String? welcomeMessage,
  });
  Future<void> changeMemberRole({
    required String orgId,
    required String userId,
    required OrgRole role,
  });
  Future<void> removeMember({
    required String orgId,
    required String userId,
    String? reassignToUserId,
  });
  Future<void> resendInvitation(String invitationId);
  Future<void> cancelInvitation(String invitationId);

  // Invitation accept.
  Future<OrgInvitation?> previewInvitation(String token);
  Future<Organization> acceptInvitation(String token);

  // Billing.
  Future<Map<String, dynamic>> getBillingSummary(String orgId);
  Future<List<Map<String, dynamic>>> listInvoices(String orgId);
  Future<String> startBillingPortal(String orgId);
  Future<void> changeSeats(String orgId, int newCount);
  Future<void> changePlan(String orgId, OrgPlan plan, bool yearly);

  // Branding.
  Future<OrgBranding> getBranding(String orgId);
  Future<OrgBranding> saveBranding(OrgBranding branding);
  Future<String> uploadLogo(String orgId, Uint8List bytes, String filename);

  // API keys.
  Future<List<ApiKey>> listApiKeys(String orgId);
  Future<ApiKeyWithSecret> createApiKey({
    required String orgId,
    required String name,
    required List<String> scopes,
    DateTime? expiresAt,
  });
  Future<void> revokeApiKey(String keyId);

  // Usage stats.
  Future<UsageStats> getUsageStats({
    required String orgId,
    required UsagePeriod period,
    DateTime? customStart,
    DateTime? customEnd,
  });

  // Dashboard.
  Future<List<Map<String, dynamic>>> getRecentActivity(String orgId,
      {int limit = 20});
}

/// Thrown for any repository-layer failure. UI layer maps `.code` to a
/// localized message via `app_*.arb`.
class OrgRepositoryException implements Exception {
  const OrgRepositoryException(this.code, [this.detail]);
  final String code;
  final String? detail;

  @override
  String toString() => 'OrgRepositoryException($code): ${detail ?? ''}';
}

// ─────────────────────────────────────────────────────────────────────────
// Supabase implementation
// ─────────────────────────────────────────────────────────────────────────

class SupabaseOrgRepository implements OrgRepository {
  SupabaseOrgRepository();

  SupabaseClient get _client => Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Invokes an edge function and unwraps the standard `{ ok, data, error }`
  /// envelope used across the B2B edge surface.
  Future<Map<String, dynamic>> _invoke(
    String functionName, {
    Map<String, dynamic>? body,
    String? orgContext,
  }) async {
    try {
      final response = await _client.functions.invoke(
        functionName,
        body: body,
        headers: {
          if (orgContext != null) 'X-Org-Context': orgContext,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['error'] != null) {
          throw OrgRepositoryException(
            data['error'] is String
                ? data['error'] as String
                : (data['error'] as Map?)?['code']?.toString() ?? 'unknown',
            data['error'] is Map ? (data['error'] as Map)['message']?.toString() : null,
          );
        }
        if (data['data'] is Map<String, dynamic>) {
          return data['data'] as Map<String, dynamic>;
        }
        return data;
      }
      if (data is List) return {'items': data};
      return {};
    } on FunctionException catch (e) {
      throw OrgRepositoryException('network_error', e.toString());
    }
  }

  @override
  Future<List<Organization>> listMyOrgs() async {
    final uid = _userId;
    if (uid == null) return const [];
    try {
      final result = await _client
          .from('organizations')
          .select('*, org_members!inner(role,joined_at,user_id)')
          .eq('org_members.user_id', uid)
          .filter('deleted_at', 'is', null)
          .order('created_at');
      return (result as List)
          .whereType<Map<String, dynamic>>()
          .map(Organization.fromJson)
          .toList();
    } catch (e) {
      // Tables may not exist yet during development — fail soft to empty
      // list so the B2C UX is never broken.
      if (kDebugMode) debugPrint('listMyOrgs failed: $e');
      return const [];
    }
  }

  @override
  Future<Organization?> getOrgBySlug(String slug) async {
    try {
      final result = await _client
          .from('organizations')
          .select('*, org_members!inner(role,joined_at,user_id)')
          .eq('slug', slug)
          .filter('deleted_at', 'is', null)
          .maybeSingle();
      if (result == null) return null;
      return Organization.fromJson(result);
    } catch (e) {
      if (kDebugMode) debugPrint('getOrgBySlug failed: $e');
      return null;
    }
  }

  @override
  Future<bool> isSlugAvailable(String slug) async {
    if (slug.length < 3) return false;
    try {
      final data = await _invoke('check-slug-availability', body: {'slug': slug});
      return (data['available'] as bool?) ?? false;
    } on OrgRepositoryException {
      // Fall back to a direct query — slugs are unique server-side anyway.
      try {
        final row = await _client
            .from('organizations')
            .select('id')
            .eq('slug', slug)
            .maybeSingle();
        return row == null;
      } catch (_) {
        return true; // Optimistic; server will 409 if not.
      }
    }
  }

  @override
  Future<Organization> createOrganization({
    required String name,
    required String slug,
    required String legalName,
    required String country,
    required String billingEmail,
    String? vatId,
    required OrgPlan plan,
    required bool yearly,
  }) async {
    final data = await _invoke('create-organization', body: {
      'name': name,
      'slug': slug,
      'legal_name': legalName,
      'country': country,
      'billing_email': billingEmail,
      'vat_id': vatId,
      'plan': plan.wire,
      'billing_period': yearly ? 'yearly' : 'monthly',
    });
    final org = data['organization'] as Map<String, dynamic>?;
    if (org == null) {
      throw const OrgRepositoryException('create_failed');
    }
    return Organization.fromJson(org);
  }

  @override
  Future<List<OrgMember>> listMembers(String orgId) async {
    try {
      final result = await _client
          .from('org_members')
          .select('id,org_id,user_id,role,invited_by,joined_at,'
              'profiles!inner(email,full_name,avatar_url)')
          .eq('org_id', orgId)
          .filter('removed_at', 'is', null)
          .order('joined_at');
      return (result as List)
          .whereType<Map<String, dynamic>>()
          .map(OrgMember.fromJson)
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('listMembers failed: $e');
      return const [];
    }
  }

  @override
  Future<List<OrgInvitation>> listPendingInvitations(String orgId) async {
    try {
      final result = await _client
          .from('org_invitations')
          .select('*')
          .eq('org_id', orgId)
          .filter('accepted_at', 'is', null)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at');
      return (result as List)
          .whereType<Map<String, dynamic>>()
          .map(OrgInvitation.fromJson)
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('listPendingInvitations failed: $e');
      return const [];
    }
  }

  @override
  Future<void> inviteMember({
    required String orgId,
    required String email,
    required OrgRole role,
    String? welcomeMessage,
  }) async {
    await _invoke('invite-member',
        orgContext: orgId,
        body: {
          'org_id': orgId,
          'email': email,
          'role': role.wire,
          if (welcomeMessage != null) 'welcome_message': welcomeMessage,
        });
  }

  @override
  Future<void> changeMemberRole({
    required String orgId,
    required String userId,
    required OrgRole role,
  }) async {
    await _invoke('change-member-role',
        orgContext: orgId,
        body: {
          'org_id': orgId,
          'user_id': userId,
          'role': role.wire,
        });
  }

  @override
  Future<void> removeMember({
    required String orgId,
    required String userId,
    String? reassignToUserId,
  }) async {
    await _invoke('remove-member',
        orgContext: orgId,
        body: {
          'org_id': orgId,
          'user_id': userId,
          if (reassignToUserId != null) 'reassign_to': reassignToUserId,
        });
  }

  @override
  Future<void> resendInvitation(String invitationId) async {
    await _invoke('resend-invitation', body: {'invitation_id': invitationId});
  }

  @override
  Future<void> cancelInvitation(String invitationId) async {
    await _invoke('cancel-invitation', body: {'invitation_id': invitationId});
  }

  @override
  Future<OrgInvitation?> previewInvitation(String token) async {
    try {
      final data = await _invoke('preview-invitation', body: {'token': token});
      return OrgInvitation.fromJson(data);
    } on OrgRepositoryException {
      return null;
    }
  }

  @override
  Future<Organization> acceptInvitation(String token) async {
    final data = await _invoke('accept-invitation', body: {'token': token});
    final org = data['organization'] as Map<String, dynamic>?;
    if (org == null) {
      throw const OrgRepositoryException('accept_failed');
    }
    return Organization.fromJson(org);
  }

  @override
  Future<Map<String, dynamic>> getBillingSummary(String orgId) async {
    return _invoke('org-billing-summary',
        orgContext: orgId, body: {'org_id': orgId});
  }

  @override
  Future<List<Map<String, dynamic>>> listInvoices(String orgId) async {
    final data = await _invoke('org-invoices',
        orgContext: orgId, body: {'org_id': orgId});
    final items = data['invoices'] ?? data['items'];
    if (items is! List) return const [];
    return items.whereType<Map<String, dynamic>>().toList();
  }

  @override
  Future<String> startBillingPortal(String orgId) async {
    final data = await _invoke('org-billing-portal',
        orgContext: orgId, body: {'org_id': orgId});
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw const OrgRepositoryException('portal_failed');
    }
    return url;
  }

  @override
  Future<void> changeSeats(String orgId, int newCount) async {
    await _invoke('change-seats',
        orgContext: orgId, body: {'org_id': orgId, 'seats': newCount});
  }

  @override
  Future<void> changePlan(String orgId, OrgPlan plan, bool yearly) async {
    await _invoke('change-plan',
        orgContext: orgId,
        body: {
          'org_id': orgId,
          'plan': plan.wire,
          'billing_period': yearly ? 'yearly' : 'monthly',
        });
  }

  @override
  Future<OrgBranding> getBranding(String orgId) async {
    try {
      final row = await _client
          .from('org_branding')
          .select('*')
          .eq('org_id', orgId)
          .maybeSingle();
      if (row == null) return OrgBranding.empty(orgId);
      return OrgBranding.fromJson(row);
    } catch (e) {
      if (kDebugMode) debugPrint('getBranding failed: $e');
      return OrgBranding.empty(orgId);
    }
  }

  @override
  Future<OrgBranding> saveBranding(OrgBranding branding) async {
    final data = await _invoke('save-org-branding',
        orgContext: branding.orgId,
        body: {
          'org_id': branding.orgId,
          'logo_url': branding.logoUrl,
          'primary_color': branding.primaryColor,
          'accent_color': branding.accentColor,
          'custom_domain': branding.customDomain,
          'support_email': branding.supportEmail,
          'footer_html': branding.footerHtml,
        });
    return OrgBranding.fromJson(data);
  }

  @override
  Future<String> uploadLogo(
      String orgId, Uint8List bytes, String filename) async {
    final ext = filename.split('.').last.toLowerCase();
    final path = '$orgId/logo.$ext';
    try {
      await _client.storage.from('org-branding').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ),
          );
      final url = _client.storage.from('org-branding').getPublicUrl(path);
      return url;
    } catch (e) {
      throw OrgRepositoryException('logo_upload_failed', e.toString());
    }
  }

  @override
  Future<List<ApiKey>> listApiKeys(String orgId) async {
    try {
      final result = await _client
          .from('org_api_keys')
          .select('*, profiles!created_by(full_name,email)')
          .eq('org_id', orgId)
          .order('created_at', ascending: false);
      return (result as List).whereType<Map<String, dynamic>>().map((row) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        if (profile != null) {
          row['created_by_name'] =
              profile['full_name'] ?? profile['email'] ?? 'Unknown';
        }
        return ApiKey.fromJson(row);
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('listApiKeys failed: $e');
      return const [];
    }
  }

  @override
  Future<ApiKeyWithSecret> createApiKey({
    required String orgId,
    required String name,
    required List<String> scopes,
    DateTime? expiresAt,
  }) async {
    final data = await _invoke('generate-api-key',
        orgContext: orgId,
        body: {
          'org_id': orgId,
          'name': name,
          'scopes': scopes,
          if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
        });
    final secret = data['secret'] as String?;
    final keyRow = data['key'] as Map<String, dynamic>?;
    if (secret == null || keyRow == null) {
      throw const OrgRepositoryException('create_key_failed');
    }
    return ApiKeyWithSecret(key: ApiKey.fromJson(keyRow), secret: secret);
  }

  @override
  Future<void> revokeApiKey(String keyId) async {
    await _invoke('revoke-api-key', body: {'key_id': keyId});
  }

  @override
  Future<UsageStats> getUsageStats({
    required String orgId,
    required UsagePeriod period,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    try {
      final data = await _invoke('org-usage-stats',
          orgContext: orgId,
          body: {
            'org_id': orgId,
            'period': period.wire,
            if (customStart != null) 'start': customStart.toIso8601String(),
            if (customEnd != null) 'end': customEnd.toIso8601String(),
          });
      return UsageStats.fromJson(data, period);
    } catch (e) {
      if (kDebugMode) debugPrint('getUsageStats failed: $e');
      return UsageStats.empty(period);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentActivity(String orgId,
      {int limit = 20}) async {
    try {
      final result = await _client
          .from('org_audit_log')
          .select('*, profiles!actor_user_id(full_name,email)')
          .eq('org_id', orgId)
          .inFilter('action', [
            'case_create',
            'document_uploaded',
            'case_resolved',
            'member_joined',
            'member_invited',
          ])
          .order('created_at', ascending: false)
          .limit(limit);
      return (result as List).whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      if (kDebugMode) debugPrint('getRecentActivity failed: $e');
      return const [];
    }
  }
}
