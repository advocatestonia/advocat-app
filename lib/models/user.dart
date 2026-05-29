class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String preferredLanguage;

  /// Authoritative Pro flag, mirrors `profiles.is_pro` boolean column.
  ///
  /// This is the SINGLE source of truth for Pro access decisions on the
  /// client. The server's `check-ai-quota` Edge Function reads the same
  /// `is_pro` column, so the frontend and backend now agree.
  ///
  /// Use [isProActive] (not [isPro]) for guard checks — it also verifies
  /// the subscription has not expired.
  ///
  /// [subscriptionTier] is retained for UI labelling only ("Basic plan",
  /// "Premium plan") and for choosing which features within Pro are
  /// available (basic = unlimited chat; premium = unlimited chat + draft
  /// generation + lawyer matching).
  final bool isPro;

  final SubscriptionTier subscriptionTier;
  final DateTime? subscriptionExpiresAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? gdprConsentAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.preferredLanguage = 'en',
    this.isPro = false,
    this.subscriptionTier = SubscriptionTier.free,
    this.subscriptionExpiresAt,
    required this.createdAt,
    this.updatedAt,
    this.gdprConsentAt,
  });

  /// Whether this user currently has active Pro access.
  ///
  /// Requires BOTH:
  ///   - [isPro] is true (server-confirmed Pro flag), AND
  ///   - [subscriptionExpiresAt] is set and in the future.
  ///
  /// Use this for ALL access-decision branches (quota visibility, Pro
  /// feature unlocks, upgrade-button visibility). Use [subscriptionTier]
  /// only for UI labelling.
  bool get isProActive {
    if (!isPro) return false;
    if (subscriptionExpiresAt == null) return false;
    return subscriptionExpiresAt!.isAfter(DateTime.now());
  }

  /// DEPRECATED: pre-unification getter that branched on tier alone.
  /// Kept for backwards compatibility with older tests; new code MUST
  /// use [isProActive].
  bool get isSubscriptionActive {
    if (subscriptionTier == SubscriptionTier.free) return false;
    if (subscriptionExpiresAt == null) return true; // no expiry set = active
    return subscriptionExpiresAt!.isAfter(DateTime.now());
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? preferredLanguage,
    bool? isPro,
    SubscriptionTier? subscriptionTier,
    DateTime? subscriptionExpiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? gdprConsentAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      isPro: isPro ?? this.isPro,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gdprConsentAt: gdprConsentAt ?? this.gdprConsentAt,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final tier = _subscriptionTierFromJson(json['subscription_tier'] as String?);

    // Backwards-compat: older payloads (before profiles.is_pro existed) did
    // not include `is_pro`. For those, infer Pro from a non-free tier so
    // existing fixtures and cached profiles keep working until they are
    // refreshed from the server.
    //
    // is_pro is a DEFAULTED, non-identity field (unlike id/created_at, which
    // fail-fast by design). It must therefore tolerate a present-but-wrong
    // type as gracefully as it tolerates absence: a stray int (0/1) or string
    // ("true"/"false") from an older serialization or a cache must NOT throw
    // and crash profile parsing — which would silently drop a paying user to
    // non-Pro via the auth_provider catch. We coerce common encodings and
    // fall back to the tier inference for anything unrecognised.
    final bool isPro;
    final rawIsPro = json['is_pro'];
    if (rawIsPro is bool) {
      isPro = rawIsPro;
    } else if (rawIsPro is num) {
      isPro = rawIsPro != 0;
    } else if (rawIsPro is String) {
      final v = rawIsPro.trim().toLowerCase();
      if (v == 'true' || v == 't' || v == '1') {
        isPro = true;
      } else if (v == 'false' || v == 'f' || v == '0' || v.isEmpty) {
        isPro = false;
      } else {
        isPro = tier != SubscriptionTier.free;
      }
    } else {
      // null or absent → infer from tier (original backwards-compat path).
      isPro = tier != SubscriptionTier.free;
    }

    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'et',
      isPro: isPro,
      subscriptionTier: tier,
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.parse(json['subscription_expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      gdprConsentAt: json['gdpr_consent_at'] != null
          ? DateTime.parse(json['gdpr_consent_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'preferred_language': preferredLanguage,
      'is_pro': isPro,
      'subscription_tier': subscriptionTier.name,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (gdprConsentAt != null)
        'gdpr_consent_at': gdprConsentAt!.toIso8601String(),
    };
  }

  static SubscriptionTier _subscriptionTierFromJson(String? value) {
    switch (value) {
      case 'basic':
        return SubscriptionTier.basic;
      case 'premium':
        return SubscriptionTier.premium;
      default:
        return SubscriptionTier.free;
    }
  }
}

enum SubscriptionTier {
  free,
  basic,
  premium,
}
