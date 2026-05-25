/// White-label branding for an organization (Firm and Enterprise plans).
///
/// Mirrors `public.org_branding`. Empty/null fields mean "use default".
class OrgBranding {
  const OrgBranding({
    required this.orgId,
    this.logoUrl,
    this.primaryColor,
    this.accentColor,
    this.customDomain,
    this.customDomainStatus,
    this.supportEmail,
    this.footerHtml,
    required this.updatedAt,
  });

  final String orgId;
  final String? logoUrl;

  /// Hex string like `#0B7A70`. Null = use Advocat default.
  final String? primaryColor;
  final String? accentColor;

  /// `firm.example.com`. Enterprise only.
  final String? customDomain;

  /// `pending_dns` | `active` | `failed` | null.
  final String? customDomainStatus;

  final String? supportEmail;
  final String? footerHtml;
  final DateTime updatedAt;

  OrgBranding copyWith({
    String? logoUrl,
    String? primaryColor,
    String? accentColor,
    String? customDomain,
    String? customDomainStatus,
    String? supportEmail,
    String? footerHtml,
  }) {
    return OrgBranding(
      orgId: orgId,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      customDomain: customDomain ?? this.customDomain,
      customDomainStatus: customDomainStatus ?? this.customDomainStatus,
      supportEmail: supportEmail ?? this.supportEmail,
      footerHtml: footerHtml ?? this.footerHtml,
      updatedAt: DateTime.now(),
    );
  }

  factory OrgBranding.fromJson(Map<String, dynamic> json) {
    return OrgBranding(
      orgId: json['org_id'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      primaryColor: json['primary_color'] as String?,
      accentColor: json['accent_color'] as String?,
      customDomain: json['custom_domain'] as String?,
      customDomainStatus: json['custom_domain_status'] as String?,
      supportEmail: json['support_email'] as String?,
      footerHtml: json['footer_html'] as String?,
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  /// Empty branding for a given org — used as initial state before
  /// the first save.
  factory OrgBranding.empty(String orgId) => OrgBranding(
        orgId: orgId,
        updatedAt: DateTime.now(),
      );

  static DateTime? _parseDate(dynamic v) {
    if (v is String) return DateTime.tryParse(v);
    if (v is DateTime) return v;
    return null;
  }
}
