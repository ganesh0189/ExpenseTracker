import '../config/constants.dart';

/// Expense model for tracking spending
class Expense {
  final int? id;
  final int userId;
  final int categoryId;
  final double amount;
  final String? merchant;
  final String? description;
  final DateTime date;
  final String? time; // Stored as HH:mm format
  final String source; // MANUAL or AUTO
  final String? notificationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional: Category name and icon for display (not stored in expenses table)
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  Expense({
    this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    this.merchant,
    this.description,
    required this.date,
    this.time,
    this.source = ExpenseSource.MANUAL,
    this.notificationId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create Expense from database map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      categoryId: map['category_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      merchant: map['merchant'] as String?,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      time: map['time'] as String?,
      source: map['source'] as String? ?? ExpenseSource.MANUAL,
      notificationId: map['notification_id'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      categoryName: map['category_name'] as String?,
      categoryIcon: map['category_icon'] as String?,
      categoryColor: map['category_color'] as String?,
    );
  }

  /// Convert Expense to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'merchant': merchant,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      'source': source,
      'notification_id': notificationId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Expense copyWith({
    int? id,
    int? userId,
    int? categoryId,
    double? amount,
    String? merchant,
    String? description,
    DateTime? date,
    String? time,
    String? source,
    String? notificationId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      source: source ?? this.source,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }

  /// Check if expense is auto-detected
  bool get isAutoDetected => source == ExpenseSource.AUTO;

  /// Check if expense is manually entered
  bool get isManual => source == ExpenseSource.MANUAL;

  /// Get display title (merchant or description or 'Expense')
  String get displayTitle {
    if (merchant != null && merchant!.isNotEmpty) return merchant!;
    if (description != null && description!.isNotEmpty) return description!;
    return 'Expense';
  }

  /// Get DateTime including time if available
  DateTime get dateTime {
    if (time != null && time!.isNotEmpty) {
      final parts = time!.split(':');
      if (parts.length >= 2) {
        return DateTime(
          date.year,
          date.month,
          date.day,
          int.tryParse(parts[0]) ?? 0,
          int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    return date;
  }

  @override
  String toString() {
    return 'Expense(id: $id, amount: $amount, merchant: $merchant, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
