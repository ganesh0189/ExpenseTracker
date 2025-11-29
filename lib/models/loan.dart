import '../config/constants.dart';

/// Loan model for tracking money lent and borrowed
class Loan {
  final int? id;
  final int userId;
  final int friendId;
  final String type; // LENT or BORROWED
  final double amount;
  final double remainingAmount;
  final String? description;
  final DateTime date;
  final DateTime? dueDate;
  final bool isSettled;
  final DateTime? settledDate;
  final bool reminderEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional: Friend name for display (not stored in loans table)
  final String? friendName;

  Loan({
    this.id,
    required this.userId,
    required this.friendId,
    required this.type,
    required this.amount,
    double? remainingAmount,
    this.description,
    required this.date,
    this.dueDate,
    this.isSettled = false,
    this.settledDate,
    this.reminderEnabled = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.friendName,
  })  : remainingAmount = remainingAmount ?? amount,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create Loan from database map
  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      friendId: map['friend_id'] as int,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      remainingAmount: (map['remaining_amount'] as num).toDouble(),
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      isSettled: (map['is_settled'] as int) == 1,
      settledDate: map['settled_date'] != null
          ? DateTime.parse(map['settled_date'] as String)
          : null,
      reminderEnabled: (map['reminder_enabled'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      friendName: map['friend_name'] as String?,
    );
  }

  /// Convert Loan to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'friend_id': friendId,
      'type': type,
      'amount': amount,
      'remaining_amount': remainingAmount,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'is_settled': isSettled ? 1 : 0,
      'settled_date': settledDate?.toIso8601String().split('T')[0],
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Loan copyWith({
    int? id,
    int? userId,
    int? friendId,
    String? type,
    double? amount,
    double? remainingAmount,
    String? description,
    DateTime? date,
    DateTime? dueDate,
    bool? isSettled,
    DateTime? settledDate,
    bool? reminderEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? friendName,
  }) {
    return Loan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      description: description ?? this.description,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      isSettled: isSettled ?? this.isSettled,
      settledDate: settledDate ?? this.settledDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      friendName: friendName ?? this.friendName,
    );
  }

  /// Check if this is a LENT loan
  bool get isLent => type == LoanType.LENT;

  /// Check if this is a BORROWED loan
  bool get isBorrowed => type == LoanType.BORROWED;

  /// Check if loan is overdue
  bool get isOverdue {
    if (isSettled || dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Get days until due or days overdue
  int get daysUntilDue {
    if (dueDate == null) return 0;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  /// Calculate paid amount
  double get paidAmount => amount - remainingAmount;

  /// Calculate payment progress (0.0 to 1.0)
  double get paymentProgress {
    if (amount == 0) return 0;
    return paidAmount / amount;
  }

  @override
  String toString() {
    return 'Loan(id: $id, type: $type, amount: $amount, remaining: $remainingAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Loan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
