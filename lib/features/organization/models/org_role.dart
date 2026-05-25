/// Roles a user can hold inside an organization.
///
/// Mirrors the `org_members.role` enum from the B2B schema
/// (see business/build/B2B_ARCHITECTURE.md §2.1).
///
/// Permission hierarchy (most → least privileged):
///   owner > admin > billing > member > viewer
enum OrgRole {
  /// Org creator; can do everything including transfer ownership and delete.
  owner('owner'),

  /// Can invite/remove members, manage all org content.
  admin('admin'),

  /// Read-only access to billing screens; otherwise like member.
  billing('billing'),

  /// Default role; can use the app on behalf of the org.
  member('member'),

  /// Read-only access to org content; cannot create.
  viewer('viewer');

  const OrgRole(this.wire);

  /// Wire-format string sent to / received from the backend.
  final String wire;

  /// Resolve from a wire-format string; defaults to [OrgRole.member] for
  /// unknown values so a future server-side role doesn't crash the client.
  static OrgRole fromWire(String? value) {
    if (value == null) return OrgRole.member;
    for (final role in OrgRole.values) {
      if (role.wire == value) return role;
    }
    return OrgRole.member;
  }

  /// Whether this role can invite or remove other members.
  bool get canManageMembers => this == owner || this == admin;

  /// Whether this role can manage billing (subscription, seats, payment).
  bool get canManageBilling =>
      this == owner || this == admin || this == billing;

  /// Whether this role can manage branding (logo, colors, custom domain).
  bool get canManageBranding => this == owner || this == admin;

  /// Whether this role can create/revoke API keys.
  bool get canManageApiKeys => this == owner || this == admin;

  /// Whether this role can create cases / documents on behalf of the org.
  bool get canCreate =>
      this == owner || this == admin || this == member;

  /// Whether this is read-only.
  bool get isReadOnly => this == viewer;
}
