import '../database_helper.dart';
import '../../models/merchant_rule.dart';

/// Repository for merchant rule database operations
class MerchantRuleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Create a new merchant rule
  Future<int> createRule(MerchantRule rule) async {
    final db = await _dbHelper.database;
    return await db.insert('merchant_rules', rule.toMap());
  }

  /// Get all rules for a user
  Future<List<MerchantRule>> getAllRules(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT mr.*, c.name as category_name
      FROM merchant_rules mr
      LEFT JOIN categories c ON mr.category_id = c.id
      WHERE mr.user_id = ?
      ORDER BY mr.merchant_name ASC
    ''', [userId]);
    return results.map((map) => MerchantRule.fromMap(map)).toList();
  }

  /// Get rule by ID
  Future<MerchantRule?> getRuleById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT mr.*, c.name as category_name
      FROM merchant_rules mr
      LEFT JOIN categories c ON mr.category_id = c.id
      WHERE mr.id = ?
      LIMIT 1
    ''', [id]);
    if (results.isEmpty) return null;
    return MerchantRule.fromMap(results.first);
  }

  /// Get rule by pattern
  Future<MerchantRule?> getRuleByPattern(int userId, String pattern) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT mr.*, c.name as category_name
      FROM merchant_rules mr
      LEFT JOIN categories c ON mr.category_id = c.id
      WHERE mr.user_id = ? AND LOWER(mr.pattern) = LOWER(?)
      LIMIT 1
    ''', [userId, pattern]);
    if (results.isEmpty) return null;
    return MerchantRule.fromMap(results.first);
  }

  /// Update rule
  Future<int> updateRule(MerchantRule rule) async {
    final db = await _dbHelper.database;
    return await db.update(
      'merchant_rules',
      rule.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  /// Delete rule
  Future<int> deleteRule(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'merchant_rules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Match merchant text against rules and return category ID
  Future<int?> matchMerchant(int userId, String merchantText) async {
    final db = await _dbHelper.database;
    final lowerMerchant = merchantText.toLowerCase();

    // Get all rules and check for matches
    final rules = await getAllRules(userId);

    for (final rule in rules) {
      if (lowerMerchant.contains(rule.pattern.toLowerCase())) {
        return rule.categoryId;
      }
    }

    return null; // No match found
  }

  /// Get rules by category
  Future<List<MerchantRule>> getRulesByCategory(int userId, int categoryId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT mr.*, c.name as category_name
      FROM merchant_rules mr
      LEFT JOIN categories c ON mr.category_id = c.id
      WHERE mr.user_id = ? AND mr.category_id = ?
      ORDER BY mr.merchant_name ASC
    ''', [userId, categoryId]);
    return results.map((map) => MerchantRule.fromMap(map)).toList();
  }

  /// Check if pattern exists for user
  Future<bool> patternExists(int userId, String pattern, {int? excludeId}) async {
    final db = await _dbHelper.database;
    String where = 'user_id = ? AND LOWER(pattern) = LOWER(?)';
    List<dynamic> whereArgs = [userId, pattern];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final results = await db.query(
      'merchant_rules',
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Get rule count for user
  Future<int> getRuleCount(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery(
      'SELECT COUNT(*) as count FROM merchant_rules WHERE user_id = ?',
      [userId],
    );
    return results.first['count'] as int;
  }

  /// Bulk insert default rules (called after category creation)
  Future<void> insertDefaultRules(int userId, Map<String, int> categoryMap) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    // categoryMap: category name -> category id
    // DEFAULT_MERCHANT_RULES: pattern -> category name

    final defaultRules = <String, String>{
      'swiggy': 'Food & Dining',
      'zomato': 'Food & Dining',
      'uber eats': 'Food & Dining',
      'dominos': 'Food & Dining',
      'mcdonald': 'Food & Dining',
      'amazon': 'Shopping',
      'flipkart': 'Shopping',
      'myntra': 'Shopping',
      'uber': 'Transportation',
      'ola': 'Transportation',
      'rapido': 'Transportation',
      'netflix': 'Entertainment',
      'hotstar': 'Entertainment',
      'spotify': 'Entertainment',
      'jio': 'Bills & Utilities',
      'airtel': 'Bills & Utilities',
      'bigbasket': 'Groceries',
      'blinkit': 'Groceries',
      'zepto': 'Groceries',
    };

    for (final entry in defaultRules.entries) {
      final categoryId = categoryMap[entry.value];
      if (categoryId != null) {
        batch.insert('merchant_rules', {
          'user_id': userId,
          'pattern': entry.key,
          'merchant_name': entry.key[0].toUpperCase() + entry.key.substring(1),
          'category_id': categoryId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }

    await batch.commit(noResult: true);
  }
}
