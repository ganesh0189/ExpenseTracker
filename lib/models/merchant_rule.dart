/// Merchant rule model for auto-categorizing expenses
class MerchantRule {
  final int? id;
  final int userId;
  final String pattern; // Pattern to match merchant name
  final String merchantName; // Display name for the merchant
  final int categoryId;
  final String? appPackage; // Optional: specific app package this rule applies to
  final DateTime createdAt;

  // Optional: Category name for display (not stored in merchant_rules table)
  final String? categoryName;

  MerchantRule({
    this.id,
    required this.userId,
    required this.pattern,
    required this.merchantName,
    required this.categoryId,
    this.appPackage,
    DateTime? createdAt,
    this.categoryName,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create MerchantRule from database map
  factory MerchantRule.fromMap(Map<String, dynamic> map) {
    return MerchantRule(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      pattern: map['pattern'] as String,
      merchantName: map['merchant_name'] as String,
      categoryId: map['category_id'] as int,
      appPackage: map['app_package'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      categoryName: map['category_name'] as String?,
    );
  }

  /// Convert MerchantRule to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'pattern': pattern,
      'merchant_name': merchantName,
      'category_id': categoryId,
      'app_package': appPackage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  MerchantRule copyWith({
    int? id,
    int? userId,
    String? pattern,
    String? merchantName,
    int? categoryId,
    String? appPackage,
    DateTime? createdAt,
    String? categoryName,
  }) {
    return MerchantRule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pattern: pattern ?? this.pattern,
      merchantName: merchantName ?? this.merchantName,
      categoryId: categoryId ?? this.categoryId,
      appPackage: appPackage ?? this.appPackage,
      createdAt: createdAt ?? this.createdAt,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  /// Check if merchant text matches this rule
  bool matches(String merchantText) {
    return merchantText.toLowerCase().contains(pattern.toLowerCase());
  }

  @override
  String toString() {
    return 'MerchantRule(id: $id, pattern: $pattern, merchantName: $merchantName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MerchantRule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
