/// API key scope identifier. Backend enforces these via prefix match.
///
/// `cases:read`, `documents:write`, `ai:invoke`, etc.
class ApiKeyScope {
  const ApiKeyScope(this.id);
  final String id;

  static const cases = [
    ApiKeyScope('cases:read'),
    ApiKeyScope('cases:write'),
    ApiKeyScope('cases:delete'),
  ];
  static const documents = [
    ApiKeyScope('documents:read'),
    ApiKeyScope('documents:write'),
  ];
  static const ai = [
    ApiKeyScope('ai:invoke'),
  ];
  static const members = [
    ApiKeyScope('members:read'),
  ];

  /// Flat list grouped under category labels for the create-key dialog.
  static const Map<String, List<ApiKeyScope>> groups = {
    'Cases': cases,
    'Documents': documents,
    'AI': ai,
    'Members': members,
  };
}

/// An API key issued for an organization.
///
/// Mirrors `public.org_api_keys` — but we NEVER see the full secret
/// after creation (only the prefix is stored client-side for display).
class ApiKey {
  const ApiKey({
    required this.id,
    required this.orgId,
    required this.name,
    required this.prefix,
    required this.scopes,
    required this.createdBy,
    this.createdByName,
    this.lastUsedAt,
    this.expiresAt,
    this.revokedAt,
    required this.createdAt,
  });

  final String id;
  final String orgId;
  final String name;

  /// `av_live_a1b2c3d4` — first 16 chars; full secret is sha256-hashed
  /// server-side and never returned again after creation.
  final String prefix;
  final List<String> scopes;
  final String createdBy;
  final String? createdByName;
  final DateTime? lastUsedAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final DateTime createdAt;

  bool get isRevoked => revokedAt != null;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isActive => !isRevoked && !isExpired;

  /// Display key (masked): "av_live_a1b2c3d4_••••••••".
  String get displayKey => '${prefix}_${'•' * 8}';

  factory ApiKey.fromJson(Map<String, dynamic> json) {
    final scopes = json['scopes'];
    return ApiKey(
      id: json['id'] as String? ?? '',
      orgId: json['org_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      prefix: json['prefix'] as String? ?? '',
      scopes: scopes is List ? scopes.map((s) => s.toString()).toList() : [],
      createdBy: json['created_by'] as String? ?? '',
      createdByName: json['created_by_name'] as String?,
      lastUsedAt: _parseDate(json['last_used_at']),
      expiresAt: _parseDate(json['expires_at']),
      revokedAt: _parseDate(json['revoked_at']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String) return DateTime.tryParse(v);
    if (v is DateTime) return v;
    return null;
  }
}

/// Returned ONCE on creation — contains the full secret.
class ApiKeyWithSecret {
  const ApiKeyWithSecret({required this.key, required this.secret});
  final ApiKey key;

  /// Full plaintext secret (e.g. `av_live_a1b2c3d4_HJ8sK2lP9mNqR4tV...`).
  /// Show ONCE, never store.
  final String secret;
}
