import '../database_helper.dart';
import '../../models/loan.dart';
import '../../models/partial_payment.dart';
import '../../config/constants.dart';

/// Repository for loan database operations
class LoanRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Create a new loan
  Future<int> createLoan(Loan loan) async {
    final db = await _dbHelper.database;
    return await db.insert('loans', loan.toMap());
  }

  /// Get all loans for a user with friend names
  Future<List<Loan>> getAllLoans(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT l.*, f.name as friend_name
      FROM loans l
      LEFT JOIN friends f ON l.friend_id = f.id
      WHERE l.user_id = ?
      ORDER BY l.date DESC
    ''', [userId]);
    return results.map((map) => Loan.fromMap(map)).toList();
  }

  /// Get loans by type (LENT or BORROWED)
  Future<List<Loan>> getLoansByType(int userId, String type) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT l.*, f.name as friend_name
      FROM loans l
      LEFT JOIN friends f ON l.friend_id = f.id
      WHERE l.user_id = ? AND l.type = ?
      ORDER BY l.date DESC
    ''', [userId, type]);
    return results.map((map) => Loan.fromMap(map)).toList();
  }

  /// Get loans by friend
  Future<List<Loan>> getLoansByFriend(int userId, int friendId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT l.*, f.name as friend_name
      FROM loans l
      LEFT JOIN friends f ON l.friend_id = f.id
      WHERE l.user_id = ? AND l.friend_id = ?
      ORDER BY l.date DESC
    ''', [userId, friendId]);
    return results.map((map) => Loan.fromMap(map)).toList();
  }

  /// Get pending (unsettled) loans
  Future<List<Loan>> getPendingLoans(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT l.*, f.name as friend_name
      FROM loans l
      LEFT JOIN friends f ON l.friend_id = f.id
      WHERE l.user_id = ? AND l.is_settled = 0
      ORDER BY l.date DESC
    ''', [userId]);
    return results.map((map) => Loan.fromMap(map)).toList();
  }

  /// Get settled loans
  Future<List<Loan>> getSettledLoans(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT l.*, f.name as friend_name
      FROM loans l
      LEFT JOIN friends f ON l.friend_id = f.id
      WHERE l.user_id = ? AND l.is_settled = 1
      ORDER BY l.settled_date DESC
    ''', [userId]);
    return results.map((map) => Loan.fromMap(map)).toList();
  }

  /// Get loan by ID
  Future<Loan?> getLoanById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT l.*, f.name as friend_name
      FROM loans l
      LEFT JOIN friends f ON l.friend_id = f.id
      WHERE l.id = ?
      LIMIT 1
    ''', [id]);
    if (results.isEmpty) return null;
    return Loan.fromMap(results.first);
  }

  /// Update loan
  Future<int> updateLoan(Loan loan) async {
    final db = await _dbHelper.database;
    return await db.update(
      'loans',
      loan.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  /// Settle loan fully
  Future<int> settleLoan(int loanId, DateTime settledDate) async {
    final db = await _dbHelper.database;
    return await db.update(
      'loans',
      {
        'is_settled': 1,
        'settled_date': settledDate.toIso8601String().split('T')[0],
        'remaining_amount': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [loanId],
    );
  }

  /// Delete loan
  Future<int> deleteLoan(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'loans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get total amount lent (pending)
  Future<double> getTotalLent(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT COALESCE(SUM(remaining_amount), 0) as total
      FROM loans
      WHERE user_id = ? AND type = ? AND is_settled = 0
    ''', [userId, LoanType.LENT]);
    return (results.first['total'] as num).toDouble();
  }

  /// Get total amount borrowed (pending)
  Future<double> getTotalBorrowed(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT COALESCE(SUM(remaining_amount), 0) as total
      FROM loans
      WHERE user_id = ? AND type = ? AND is_settled = 0
    ''', [userId, LoanType.BORROWED]);
    return (results.first['total'] as num).toDouble();
  }

  /// Get loan count by type (pending)
  Future<int> getPendingLoanCount(int userId, String type) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM loans
      WHERE user_id = ? AND type = ? AND is_settled = 0
    ''', [userId, type]);
    return results.first['count'] as int;
  }

  /// Add partial payment
  Future<int> addPartialPayment(PartialPayment payment) async {
    final db = await _dbHelper.database;

    // Insert partial payment
    final paymentId = await db.insert('partial_payments', payment.toMap());

    // Update loan remaining amount
    final loan = await getLoanById(payment.loanId);
    if (loan != null) {
      final newRemaining = loan.remainingAmount - payment.amount;
      await db.update(
        'loans',
        {
          'remaining_amount': newRemaining < 0 ? 0 : newRemaining,
          'is_settled': newRemaining <= 0 ? 1 : 0,
          'settled_date': newRemaining <= 0
              ? DateTime.now().toIso8601String().split('T')[0]
              : null,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [payment.loanId],
      );
    }

    return paymentId;
  }

  /// Get partial payments for a loan
  Future<List<PartialPayment>> getPartialPayments(int loanId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'partial_payments',
      where: 'loan_id = ?',
      whereArgs: [loanId],
      orderBy: 'date DESC',
    );
    return results.map((map) => PartialPayment.fromMap(map)).toList();
  }

  /// Get overdue loans
  Future<List<Loan>> getOverdueLoans(int userId) async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final results = await db.rawQuery('''
      SELECT l.*, f.name as friend_name
      FROM loans l
      LEFT JOIN friends f ON l.friend_id = f.id
      WHERE l.user_id = ? AND l.is_settled = 0 AND l.due_date IS NOT NULL AND l.due_date < ?
      ORDER BY l.due_date ASC
    ''', [userId, today]);
    return results.map((map) => Loan.fromMap(map)).toList();
  }

  /// Get recent loan activities (for dashboard)
  Future<List<Map<String, dynamic>>> getRecentLoanActivities(int userId, {int limit = 5}) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT l.*, f.name as friend_name, 'loan' as activity_type
      FROM loans l
      LEFT JOIN friends f ON l.friend_id = f.id
      WHERE l.user_id = ?
      ORDER BY l.created_at DESC
      LIMIT ?
    ''', [userId, limit]);
  }
}
