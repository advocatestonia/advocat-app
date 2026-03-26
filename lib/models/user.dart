class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String preferredLanguage;
  final SubscriptionTier subscriptionTier;
  final DateTime? subscriptionExpiresAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.preferredLanguage = 'en',
    this.subscriptionTier = SubscriptionTier.free,
    this.subscriptionExpiresAt,
    required this.createdAt,
    this.updatedAt,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? preferredLanguage,
    SubscriptionTier? subscriptionTier,
    DateTime? subscriptionExpiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      subscriptionTier: _subscriptionTierFromJson(json['subscription_tier'] as String?),
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.parse(json['subscription_expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'preferred_language': preferredLanguage,
      'subscription_tier': subscriptionTier.name,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
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
