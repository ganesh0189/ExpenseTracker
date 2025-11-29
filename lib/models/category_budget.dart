/// Category budget model for per-category spending limits
class CategoryBudget {
  final int? id;
  final int userId;
  final int categoryId;
  final double amount;
  final int month; // 1-12
  final int year;
  final DateTime createdAt;

  // Optional: Category name for display
  final String? categoryName;

  CategoryBudget({
    this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
    DateTime? createdAt,
    this.categoryName,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create CategoryBudget from database map
  factory CategoryBudget.fromMap(Map<String, dynamic> map) {
    return CategoryBudget(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      categoryId: map['category_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      month: map['month'] as int,
      year: map['year'] as int,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      categoryName: map['category_name'] as String?,
    );
  }

  /// Convert CategoryBudget to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'month': month,
      'year': year,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  CategoryBudget copyWith({
    int? id,
    int? userId,
    int? categoryId,
    double? amount,
    int? month,
    int? year,
    DateTime? createdAt,
    String? categoryName,
  }) {
    return CategoryBudget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  @override
  String toString() {
    return 'CategoryBudget(id: $id, categoryId: $categoryId, amount: $amount, month: $month/$year)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryBudget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
