import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_key.dart';
import '../models/org_branding.dart';
import '../models/org_invitation.dart';
import '../models/org_member.dart';
import '../models/org_role.dart';
import '../models/organization.dart';
import '../models/usage_stats.dart';
import '../repositories/org_repository.dart';

// ─── Active org context ─────────────────────────────────────────────────

/// Storage key for the active-org id in SharedPreferences. Persisted so
/// re-opening the app puts the user back in the same org context.
const _kActiveOrgIdKey = 'advocat_active_org_id';

/// The currently selected org id (null = personal / B2C context).
///
/// Persisted to SharedPreferences across launches. Mutating this state
/// causes every `org_id`-scoped provider to refresh.
final activeOrgIdProvider =
    StateNotifierProvider<ActiveOrgIdNotifier, String?>((ref) {
  return ActiveOrgIdNotifier();
});

class ActiveOrgIdNotifier extends StateNotifier<String?> {
  ActiveOrgIdNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kActiveOrgIdKey);
      if (saved != null && saved.isNotEmpty && mounted) {
        state = saved;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('ActiveOrgIdNotifier load failed: $e');
    }
  }

  Future<void> setActive(String? orgId) async {
    state = orgId;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (orgId == null) {
        await prefs.remove(_kActiveOrgIdKey);
      } else {
        await prefs.setString(_kActiveOrgIdKey, orgId);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('ActiveOrgIdNotifier save failed: $e');
    }
  }
}

// ─── Org list / membership ──────────────────────────────────────────────

/// All orgs the current user is a member of.
final myOrgsProvider = FutureProvider.autoDispose<List<Organization>>((ref) async {
  final repo = ref.watch(orgRepositoryProvider);
  return repo.listMyOrgs();
});

/// Returns true when the current user is a member of at least one org.
/// Used by `MainShell` to decide whether to surface the Organization tab.
final hasAnyOrgProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(myOrgsProvider).maybeWhen(
        data: (orgs) => orgs.isNotEmpty,
        orElse: () => false,
      );
});

/// The currently active organization (resolved from id + list).
final activeOrgProvider = Provider.autoDispose<Organization?>((ref) {
  final id = ref.watch(activeOrgIdProvider);
  if (id == null) return null;
  final orgs = ref.watch(myOrgsProvider).maybeWhen(
        data: (list) => list,
        orElse: () => <Organization>[],
      );
  for (final o in orgs) {
    if (o.id == id) return o;
  }
  return null;
});

/// The current user's role in the active org (null in personal context).
final activeOrgRoleProvider = Provider.autoDispose<OrgRole?>((ref) {
  return ref.watch(activeOrgProvider)?.myRole;
});

/// Resolve org by slug — used by GoRouter to look up the active org from
/// `/orgs/<slug>/...` paths and validate membership.
final orgBySlugProvider =
    FutureProvider.autoDispose.family<Organization?, String>((ref, slug) async {
  final repo = ref.watch(orgRepositoryProvider);
  // Try local cache first.
  final orgs = ref.read(myOrgsProvider).valueOrNull ?? const <Organization>[];
  for (final o in orgs) {
    if (o.slug == slug) return o;
  }
  return repo.getOrgBySlug(slug);
});

// ─── Members / Invitations ──────────────────────────────────────────────

final orgMembersProvider =
    FutureProvider.autoDispose.family<List<OrgMember>, String>((ref, orgId) {
  return ref.watch(orgRepositoryProvider).listMembers(orgId);
});

final orgPendingInvitationsProvider = FutureProvider.autoDispose
    .family<List<OrgInvitation>, String>((ref, orgId) {
  return ref.watch(orgRepositoryProvider).listPendingInvitations(orgId);
});

// ─── Billing ────────────────────────────────────────────────────────────

final orgBillingSummaryProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, orgId) {
  return ref.watch(orgRepositoryProvider).getBillingSummary(orgId);
});

final orgInvoicesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, orgId) {
  return ref.watch(orgRepositoryProvider).listInvoices(orgId);
});

// ─── Branding ───────────────────────────────────────────────────────────

final orgBrandingProvider =
    FutureProvider.autoDispose.family<OrgBranding, String>((ref, orgId) {
  return ref.watch(orgRepositoryProvider).getBranding(orgId);
});

/// Held in-memory while the user is editing branding (debounced auto-save
/// happens in the screen). Cleared on screen disposal via autoDispose.
final brandingDraftProvider =
    StateNotifierProvider.autoDispose.family<BrandingDraftNotifier,
        OrgBranding?, String>((ref, orgId) {
  return BrandingDraftNotifier(orgId, ref);
});

class BrandingDraftNotifier extends StateNotifier<OrgBranding?> {
  BrandingDraftNotifier(this.orgId, this._ref) : super(null) {
    _ref.listen(orgBrandingProvider(orgId), (_, next) {
      next.whenData((b) {
        // Only seed the draft from the server on first load — subsequent
        // server refreshes shouldn't clobber unsaved local edits.
        if (state == null) state = b;
      });
    }, fireImmediately: true);
  }

  final String orgId;
  final Ref _ref;

  void update(OrgBranding next) => state = next;
}

// ─── API keys ───────────────────────────────────────────────────────────

final orgApiKeysProvider =
    FutureProvider.autoDispose.family<List<ApiKey>, String>((ref, orgId) {
  return ref.watch(orgRepositoryProvider).listApiKeys(orgId);
});

// ─── Usage stats ────────────────────────────────────────────────────────

class UsageStatsArgs {
  const UsageStatsArgs({
    required this.orgId,
    required this.period,
    this.customStart,
    this.customEnd,
  });
  final String orgId;
  final UsagePeriod period;
  final DateTime? customStart;
  final DateTime? customEnd;

  @override
  bool operator ==(Object other) =>
      other is UsageStatsArgs &&
      other.orgId == orgId &&
      other.period == period &&
      other.customStart == customStart &&
      other.customEnd == customEnd;

  @override
  int get hashCode =>
      Object.hash(orgId, period, customStart, customEnd);
}

final orgUsageStatsProvider = FutureProvider.autoDispose
    .family<UsageStats, UsageStatsArgs>((ref, args) {
  return ref.watch(orgRepositoryProvider).getUsageStats(
        orgId: args.orgId,
        period: args.period,
        customStart: args.customStart,
        customEnd: args.customEnd,
      );
});

// ─── Dashboard ──────────────────────────────────────────────────────────

final orgRecentActivityProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, orgId) {
  return ref.watch(orgRepositoryProvider).getRecentActivity(orgId);
});
