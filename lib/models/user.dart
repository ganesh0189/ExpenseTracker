/// User model representing app user
class User {
  final int? id;
  final String fullName;
  final String username;
  final String passwordHash;
  final String? pinHash;
  final String currencySymbol;
  final double monthlyBudget;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    this.id,
    required this.fullName,
    required this.username,
    required this.passwordHash,
    this.pinHash,
    this.currencySymbol = '₹',
    this.monthlyBudget = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create User from database map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      fullName: map['full_name'] as String,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      pinHash: map['pin_hash'] as String?,
      currencySymbol: map['currency_symbol'] as String? ?? '₹',
      monthlyBudget: (map['monthly_budget'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert User to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'full_name': fullName,
      'username': username,
      'password_hash': passwordHash,
      'pin_hash': pinHash,
      'currency_symbol': currencySymbol,
      'monthly_budget': monthlyBudget,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  User copyWith({
    int? id,
    String? fullName,
    String? username,
    String? passwordHash,
    String? pinHash,
    String? currencySymbol,
    double? monthlyBudget,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      pinHash: pinHash ?? this.pinHash,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Check if user has PIN set
  bool get hasPin => pinHash != null && pinHash!.isNotEmpty;

  @override
  String toString() {
    return 'User(id: $id, fullName: $fullName, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
