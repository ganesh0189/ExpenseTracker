import '../database_helper.dart';
import '../../models/category_budget.dart';

/// Repository for app settings database operations
class SettingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ============ App Settings ============

  /// Get setting value by key
  Future<String?> getSetting(int userId, String key) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'app_settings',
      where: 'user_id = ? AND key = ?',
      whereArgs: [userId, key],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['value'] as String;
  }

  /// Set setting value
  Future<void> setSetting(int userId, String key, String value) async {
    final db = await _dbHelper.database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO app_settings (user_id, key, value) VALUES (?, ?, ?)',
      [userId, key, value],
    );
  }

  /// Delete setting
  Future<int> deleteSetting(int userId, String key) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'app_settings',
      where: 'user_id = ? AND key = ?',
      whereArgs: [userId, key],
    );
  }

  /// Get all settings for user
  Future<Map<String, String>> getAllSettings(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'app_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    final settings = <String, String>{};
    for (final row in results) {
      settings[row['key'] as String] = row['value'] as String;
    }
    return settings;
  }

  // ============ Category Budgets ============

  /// Create or update category budget
  Future<int> setCategoryBudget(CategoryBudget budget) async {
    final db = await _dbHelper.database;
    final map = budget.toMap();
    return await db.rawInsert(
      '''INSERT OR REPLACE INTO category_budgets
         (user_id, category_id, month, year, budget_amount)
         VALUES (?, ?, ?, ?, ?)''',
      [map['user_id'], map['category_id'], map['month'], map['year'], map['budget_amount']],
    );
  }

  /// Get category budget for a specific month
  Future<CategoryBudget?> getCategoryBudget(
    int userId,
    int categoryId,
    int month,
    int year,
  ) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT cb.*, c.name as category_name
      FROM category_budgets cb
      LEFT JOIN categories c ON cb.category_id = c.id
      WHERE cb.user_id = ? AND cb.category_id = ? AND cb.month = ? AND cb.year = ?
      LIMIT 1
    ''', [userId, categoryId, month, year]);
    if (results.isEmpty) return null;
    return CategoryBudget.fromMap(results.first);
  }

  /// Get all category budgets for a month
  Future<List<CategoryBudget>> getAllCategoryBudgets(
    int userId,
    int month,
    int year,
  ) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT cb.*, c.name as category_name
      FROM category_budgets cb
      LEFT JOIN categories c ON cb.category_id = c.id
      WHERE cb.user_id = ? AND cb.month = ? AND cb.year = ?
      ORDER BY c.name ASC
    ''', [userId, month, year]);
    return results.map((map) => CategoryBudget.fromMap(map)).toList();
  }

  /// Delete category budget
  Future<int> deleteCategoryBudget(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'category_budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get total budget for a month (sum of all category budgets)
  Future<double> getTotalCategoryBudget(int userId, int month, int year) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM category_budgets
      WHERE user_id = ? AND month = ? AND year = ?
    ''', [userId, month, year]);
    return (results.first['total'] as num).toDouble();
  }

  /// Copy budgets from one month to another
  Future<void> copyBudgetsToMonth(
    int userId,
    int fromMonth,
    int fromYear,
    int toMonth,
    int toYear,
  ) async {
    final db = await _dbHelper.database;
    final existingBudgets = await getAllCategoryBudgets(userId, fromMonth, fromYear);

    for (final budget in existingBudgets) {
      await db.rawInsert(
        '''INSERT OR REPLACE INTO category_budgets
           (user_id, category_id, budget_amount, month, year)
           VALUES (?, ?, ?, ?, ?)''',
        [userId, budget.categoryId, budget.amount, toMonth, toYear],
      );
    }
  }

  // ============ Data Management ============

  /// Delete all user data (factory reset)
  Future<void> deleteAllUserData(int userId) async {
    final db = await _dbHelper.database;

    // Delete in order to respect foreign keys
    await db.delete('partial_payments', where: 'loan_id IN (SELECT id FROM loans WHERE user_id = ?)', whereArgs: [userId]);
    await db.delete('loans', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('expenses', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('merchant_rules', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('category_budgets', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('categories', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('friends', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('monitored_apps', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('app_settings', where: 'user_id = ?', whereArgs: [userId]);
  }

  /// Delete all expenses for user
  Future<int> deleteAllExpenses(int userId) async {
    final db = await _dbHelper.database;
    return await db.delete('expenses', where: 'user_id = ?', whereArgs: [userId]);
  }

  /// Delete all loans for user
  Future<int> deleteAllLoans(int userId) async {
    final db = await _dbHelper.database;
    await db.delete('partial_payments', where: 'loan_id IN (SELECT id FROM loans WHERE user_id = ?)', whereArgs: [userId]);
    return await db.delete('loans', where: 'user_id = ?', whereArgs: [userId]);
  }
}

/// Conflict algorithm for SQLite
enum ConflictAlgorithm {
  rollback,
  abort,
  fail,
  ignore,
  replace,
}

extension ConflictAlgorithmExtension on ConflictAlgorithm {
  int get value {
    switch (this) {
      case ConflictAlgorithm.rollback:
        return 1;
      case ConflictAlgorithm.abort:
        return 2;
      case ConflictAlgorithm.fail:
        return 3;
      case ConflictAlgorithm.ignore:
        return 4;
      case ConflictAlgorithm.replace:
        return 5;
    }
  }
}
