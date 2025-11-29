import '../database_helper.dart';
import '../../models/expense.dart';

/// Repository for expense database operations
class ExpenseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Create a new expense
  Future<int> createExpense(Expense expense) async {
    final db = await _dbHelper.database;
    return await db.insert('expenses', expense.toMap());
  }

  /// Get all expenses for a user with category info
  Future<List<Expense>> getAllExpenses(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT e.*, c.name as category_name, c.icon as category_icon, c.color as category_color
      FROM expenses e
      LEFT JOIN categories c ON e.category_id = c.id
      WHERE e.user_id = ?
      ORDER BY e.date DESC, e.time DESC
    ''', [userId]);
    return results.map((map) => Expense.fromMap(map)).toList();
  }

  /// Get expenses by date range
  Future<List<Expense>> getExpensesByDateRange(
    int userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];

    final results = await db.rawQuery('''
      SELECT e.*, c.name as category_name, c.icon as category_icon, c.color as category_color
      FROM expenses e
      LEFT JOIN categories c ON e.category_id = c.id
      WHERE e.user_id = ? AND e.date >= ? AND e.date <= ?
      ORDER BY e.date DESC, e.time DESC
    ''', [userId, startStr, endStr]);
    return results.map((map) => Expense.fromMap(map)).toList();
  }

  /// Get expenses by category
  Future<List<Expense>> getExpensesByCategory(int userId, int categoryId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT e.*, c.name as category_name, c.icon as category_icon, c.color as category_color
      FROM expenses e
      LEFT JOIN categories c ON e.category_id = c.id
      WHERE e.user_id = ? AND e.category_id = ?
      ORDER BY e.date DESC, e.time DESC
    ''', [userId, categoryId]);
    return results.map((map) => Expense.fromMap(map)).toList();
  }

  /// Get expenses by month
  Future<List<Expense>> getExpensesByMonth(int userId, int month, int year) async {
    final db = await _dbHelper.database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    return getExpensesByDateRange(userId, startDate, endDate);
  }

  /// Get expense by ID
  Future<Expense?> getExpenseById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT e.*, c.name as category_name, c.icon as category_icon, c.color as category_color
      FROM expenses e
      LEFT JOIN categories c ON e.category_id = c.id
      WHERE e.id = ?
      LIMIT 1
    ''', [id]);
    if (results.isEmpty) return null;
    return Expense.fromMap(results.first);
  }

  /// Update expense
  Future<int> updateExpense(Expense expense) async {
    final db = await _dbHelper.database;
    return await db.update(
      'expenses',
      expense.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  /// Delete expense
  Future<int> deleteExpense(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get total expenses by month
  Future<double> getTotalExpensesByMonth(int userId, int month, int year) async {
    final db = await _dbHelper.database;
    final startDate = DateTime(year, month, 1).toIso8601String().split('T')[0];
    final endDate = DateTime(year, month + 1, 0).toIso8601String().split('T')[0];

    final results = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM expenses
      WHERE user_id = ? AND date >= ? AND date <= ?
    ''', [userId, startDate, endDate]);
    return (results.first['total'] as num).toDouble();
  }

  /// Get expenses by source (MANUAL or AUTO)
  Future<List<Expense>> getExpensesBySource(int userId, String source) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT e.*, c.name as category_name, c.icon as category_icon, c.color as category_color
      FROM expenses e
      LEFT JOIN categories c ON e.category_id = c.id
      WHERE e.user_id = ? AND e.source = ?
      ORDER BY e.date DESC, e.time DESC
    ''', [userId, source]);
    return results.map((map) => Expense.fromMap(map)).toList();
  }

  /// Get category-wise totals for a month
  Future<List<Map<String, dynamic>>> getCategoryWiseTotal(
    int userId,
    int month,
    int year,
  ) async {
    final db = await _dbHelper.database;
    final startDate = DateTime(year, month, 1).toIso8601String().split('T')[0];
    final endDate = DateTime(year, month + 1, 0).toIso8601String().split('T')[0];

    return await db.rawQuery('''
      SELECT
        c.id as category_id,
        c.name as category_name,
        c.icon as category_icon,
        c.color as category_color,
        COALESCE(SUM(e.amount), 0) as total,
        COUNT(e.id) as count
      FROM categories c
      LEFT JOIN expenses e ON c.id = e.category_id
        AND e.user_id = ?
        AND e.date >= ?
        AND e.date <= ?
      WHERE c.user_id = ? AND c.is_hidden = 0
      GROUP BY c.id
      HAVING total > 0
      ORDER BY total DESC
    ''', [userId, startDate, endDate, userId]);
  }

  /// Check if notification ID already exists (for deduplication)
  Future<bool> notificationIdExists(String notificationId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'expenses',
      where: 'notification_id = ?',
      whereArgs: [notificationId],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Get recent expenses for dashboard
  Future<List<Expense>> getRecentExpenses(int userId, {int limit = 5}) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT e.*, c.name as category_name, c.icon as category_icon, c.color as category_color
      FROM expenses e
      LEFT JOIN categories c ON e.category_id = c.id
      WHERE e.user_id = ?
      ORDER BY e.date DESC, e.time DESC, e.created_at DESC
      LIMIT ?
    ''', [userId, limit]);
    return results.map((map) => Expense.fromMap(map)).toList();
  }

  /// Get expenses grouped by date (for list display)
  Future<Map<String, List<Expense>>> getExpensesGroupedByDate(
    int userId,
    int month,
    int year,
  ) async {
    final expenses = await getExpensesByMonth(userId, month, year);
    final grouped = <String, List<Expense>>{};

    for (final expense in expenses) {
      final dateKey = expense.date.toIso8601String().split('T')[0];
      grouped.putIfAbsent(dateKey, () => []).add(expense);
    }

    return grouped;
  }

  /// Get expense count for user
  Future<int> getExpenseCount(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery(
      'SELECT COUNT(*) as count FROM expenses WHERE user_id = ?',
      [userId],
    );
    return results.first['count'] as int;
  }

  /// Delete all expenses for user (for data reset)
  Future<int> deleteAllExpenses(int userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'expenses',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
