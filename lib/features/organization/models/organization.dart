import 'org_role.dart';

/// Subscription plan a B2B organization is on.
///
/// Plan capabilities (see B2B_ARCHITECTURE.md §4):
///   starter    — up to 5 seats, basic features
///   firm       — up to 25 seats, branding lite + API
///   enterprise — unlimited seats, white-label + SSO
enum OrgPlan {
  starter('starter', 5, 29.0),
  firm('firm', 25, 49.0),
  enterprise('enterprise', 100000, 99.0);

  const OrgPlan(this.wire, this.seatLimit, this.pricePerSeatMonthly);

  final String wire;
  final int seatLimit;
  final double pricePerSeatMonthly;

  static OrgPlan fromWire(String? value) {
    for (final plan in OrgPlan.values) {
      if (plan.wire == value) return plan;
    }
    return OrgPlan.starter;
  }

  /// Yearly price (-16.7% vs monthly * 12 — i.e. ~2 months free).
  double get pricePerSeatYearly => pricePerSeatMonthly * 12 * 0.833;

  bool get hasBranding => this == firm || this == enterprise;
  bool get hasApiAccess => this == firm || this == enterprise;
  bool get hasWhiteLabel => this == enterprise;
  bool get hasCustomDomain => this == enterprise;
}

/// Lifecycle status of an organization's subscription.
enum OrgStatus {
  trial('trial'),
  active('active'),
  pastDue('past_due'),
  canceled('canceled'),
  suspended('suspended');

  const OrgStatus(this.wire);
  final String wire;

  static OrgStatus fromWire(String? value) {
    for (final s in OrgStatus.values) {
      if (s.wire == value) return s;
    }
    return OrgStatus.trial;
  }

  bool get isActive => this == active || this == trial;
}

/// A B2B organization (law firm, in-house legal team, etc.).
///
/// Mirrors `public.organizations` plus a denormalized `myRole` column
/// loaded from the `org_members` join (see B2B_ARCHITECTURE.md §2.1).
class Organization {
  const Organization({
    required this.id,
    required this.slug,
    required this.name,
    required this.legalName,
    this.vatId,
    required this.country,
    required this.billingEmail,
    required this.plan,
    required this.seatCount,
    required this.seatLimit,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.trialEndsAt,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.myRole,
  });

  final String id;
  final String slug;
  final String name;
  final String legalName;
  final String? vatId;
  final String country;
  final String billingEmail;
  final OrgPlan plan;
  final int seatCount;
  final int seatLimit;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final DateTime? trialEndsAt;
  final OrgStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The current user's role in this org. Populated by the
  /// `myOrgs` query via `org_members!inner(role)`. May be null when the
  /// org is loaded outside of a membership context (e.g. an invite preview).
  final OrgRole? myRole;

  bool get isOnTrial => status == OrgStatus.trial && trialEndsAt != null;

  /// Days remaining in the trial (negative if expired). Returns null when
  /// not on a trial.
  int? get trialDaysRemaining {
    final end = trialEndsAt;
    if (end == null || status != OrgStatus.trial) return null;
    return end.difference(DateTime.now()).inDays;
  }

  bool get hasAvailableSeats => seatCount < seatLimit;

  Organization copyWith({
    String? name,
    String? legalName,
    String? vatId,
    String? billingEmail,
    OrgPlan? plan,
    int? seatCount,
    int? seatLimit,
    OrgStatus? status,
    OrgRole? myRole,
  }) {
    return Organization(
      id: id,
      slug: slug,
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      vatId: vatId ?? this.vatId,
      country: country,
      billingEmail: billingEmail ?? this.billingEmail,
      plan: plan ?? this.plan,
      seatCount: seatCount ?? this.seatCount,
      seatLimit: seatLimit ?? this.seatLimit,
      stripeCustomerId: stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId,
      trialEndsAt: trialEndsAt,
      status: status ?? this.status,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      myRole: myRole ?? this.myRole,
    );
  }

  factory Organization.fromJson(Map<String, dynamic> json) {
    // The `org_members!inner(role)` join surfaces as a nested list/object.
    OrgRole? myRole;
    final members = json['org_members'];
    if (members is List && members.isNotEmpty) {
      final first = members.first;
      if (first is Map<String, dynamic>) {
        myRole = OrgRole.fromWire(first['role'] as String?);
      }
    } else if (members is Map<String, dynamic>) {
      myRole = OrgRole.fromWire(members['role'] as String?);
    } else if (json['my_role'] is String) {
      myRole = OrgRole.fromWire(json['my_role'] as String);
    }

    return Organization(
      id: json['id'] as String,
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      legalName: json['legal_name'] as String? ?? '',
      vatId: json['vat_id'] as String?,
      country: json['country'] as String? ?? 'EE',
      billingEmail: json['billing_email'] as String? ?? '',
      plan: OrgPlan.fromWire(json['plan'] as String?),
      seatCount: (json['seat_count'] as num?)?.toInt() ?? 0,
      seatLimit: (json['seat_limit'] as num?)?.toInt() ?? 5,
      stripeCustomerId: json['stripe_customer_id'] as String?,
      stripeSubscriptionId: json['stripe_subscription_id'] as String?,
      trialEndsAt: _parseDate(json['trial_ends_at']),
      status: OrgStatus.fromWire(json['status'] as String?),
      createdBy: json['created_by'] as String? ?? '',
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
      myRole: myRole,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String) return DateTime.tryParse(v);
    if (v is DateTime) return v;
    return null;
  }
}
