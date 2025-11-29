/// Partial payment model for tracking loan repayments
class PartialPayment {
  final int? id;
  final int loanId;
  final double amount;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  PartialPayment({
    this.id,
    required this.loanId,
    required this.amount,
    required this.date,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create PartialPayment from database map
  factory PartialPayment.fromMap(Map<String, dynamic> map) {
    return PartialPayment(
      id: map['id'] as int?,
      loanId: map['loan_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert PartialPayment to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'loan_id': loanId,
      'amount': amount,
      'date': date.toIso8601String().split('T')[0],
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  PartialPayment copyWith({
    int? id,
    int? loanId,
    double? amount,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
  }) {
    return PartialPayment(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'PartialPayment(id: $id, loanId: $loanId, amount: $amount, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PartialPayment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
