import 'org_role.dart';

/// A pending invitation to join an organization.
///
/// Mirrors `public.org_invitations`. The raw `token` is never sent to the
/// client; we only ever expose the email + role + expiry for display.
class OrgInvitation {
  const OrgInvitation({
    required this.id,
    required this.orgId,
    required this.email,
    required this.role,
    required this.invitedBy,
    required this.expiresAt,
    this.acceptedAt,
    required this.createdAt,
    this.orgName,
    this.inviterName,
  });

  final String id;
  final String orgId;
  final String email;
  final OrgRole role;
  final String invitedBy;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final DateTime createdAt;

  /// Org name — populated by the `invitation_preview` RPC for the
  /// invitation accept screen.
  final String? orgName;

  /// Inviter's display name — same source as [orgName].
  final String? inviterName;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => acceptedAt == null && !isExpired;

  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  factory OrgInvitation.fromJson(Map<String, dynamic> json) {
    return OrgInvitation(
      id: json['id'] as String? ?? '',
      orgId: json['org_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: OrgRole.fromWire(json['role'] as String?),
      invitedBy: json['invited_by'] as String? ?? '',
      expiresAt: _parseDate(json['expires_at']) ??
          DateTime.now().add(const Duration(days: 7)),
      acceptedAt: _parseDate(json['accepted_at']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      orgName: json['org_name'] as String?,
      inviterName: json['inviter_name'] as String? ??
          json['invited_by_name'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String) return DateTime.tryParse(v);
    if (v is DateTime) return v;
    return null;
  }
}
