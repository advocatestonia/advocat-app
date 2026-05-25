import 'org_role.dart';

/// A user's membership in an organization.
///
/// Mirrors `public.org_members` joined with `public.profiles` so the UI
/// has the member's display name + email without a second round-trip.
class OrgMember {
  const OrgMember({
    required this.id,
    required this.orgId,
    required this.userId,
    required this.role,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.invitedBy,
    required this.joinedAt,
  });

  final String id;
  final String orgId;
  final String userId;
  final OrgRole role;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? invitedBy;
  final DateTime joinedAt;

  /// Display name fallback chain: full_name → local part of email → "User".
  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) return fullName!;
    final at = email.indexOf('@');
    if (at > 0) return email.substring(0, at);
    return 'User';
  }

  /// Single-letter avatar fallback (first non-whitespace of displayName).
  String get initial {
    for (final c in displayName.runes) {
      final s = String.fromCharCode(c);
      if (s.trim().isNotEmpty) return s.toUpperCase();
    }
    return '?';
  }

  factory OrgMember.fromJson(Map<String, dynamic> json) {
    // Profiles may be embedded under `profiles` key, or flattened
    // (depending on whether the edge function reshapes the join).
    final profile = json['profiles'] as Map<String, dynamic>? ?? json;
    return OrgMember(
      id: json['id'] as String? ?? '',
      orgId: json['org_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      role: OrgRole.fromWire(json['role'] as String?),
      email: profile['email'] as String? ?? json['email'] as String? ?? '',
      fullName: profile['full_name'] as String? ?? json['full_name'] as String?,
      avatarUrl:
          profile['avatar_url'] as String? ?? json['avatar_url'] as String?,
      invitedBy: json['invited_by'] as String?,
      joinedAt: _parseDate(json['joined_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String) return DateTime.tryParse(v);
    if (v is DateTime) return v;
    return null;
  }
}
