class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String preferredLanguage;
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
    this.subscriptionTier = SubscriptionTier.free,
    this.subscriptionExpiresAt,
    required this.createdAt,
    this.updatedAt,
    this.gdprConsentAt,
  });

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
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gdprConsentAt: gdprConsentAt ?? this.gdprConsentAt,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'et',
      subscriptionTier: _subscriptionTierFromJson(json['subscription_tier'] as String?),
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
