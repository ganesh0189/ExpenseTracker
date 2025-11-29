import '../database_helper.dart';
import '../../models/category.dart';
import '../../config/constants.dart';

/// Repository for category database operations
class CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Create a new category
  Future<int> createCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.insert('categories', category.toMap());
  }

  /// Get all categories for a user
  Future<List<Category>> getAllCategories(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'categories',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'sort_order ASC, name ASC',
    );
    return results.map((map) => Category.fromMap(map)).toList();
  }

  /// Get visible (non-hidden) categories
  Future<List<Category>> getVisibleCategories(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'categories',
      where: 'user_id = ? AND is_hidden = 0',
      whereArgs: [userId],
      orderBy: 'sort_order ASC, name ASC',
    );
    return results.map((map) => Category.fromMap(map)).toList();
  }

  /// Get category by ID
  Future<Category?> getCategoryById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Category.fromMap(results.first);
  }

  /// Get category by name for a user
  Future<Category?> getCategoryByName(int userId, String name) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'categories',
      where: 'user_id = ? AND LOWER(name) = LOWER(?)',
      whereArgs: [userId, name],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Category.fromMap(results.first);
  }

  /// Update category
  Future<int> updateCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Hide category (for default categories)
  Future<int> hideCategory(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'categories',
      {'is_hidden': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Show (unhide) category
  Future<int> showCategory(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'categories',
      {'is_hidden': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete category (only for custom categories)
  Future<int> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    // Only delete if not a default category
    return await db.delete(
      'categories',
      where: 'id = ? AND is_default = 0',
      whereArgs: [id],
    );
  }

  /// Insert default categories for a new user
  Future<void> insertDefaultCategories(int userId) async {
    final db = await _dbHelper.database;

    for (int i = 0; i < DEFAULT_CATEGORIES.length; i++) {
      final cat = DEFAULT_CATEGORIES[i];
      await db.insert('categories', {
        'user_id': userId,
        'name': cat.name,
        'icon': cat.icon,
        'color': cat.color,
        'is_default': 1,
        'is_hidden': 0,
        'sort_order': i,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Update category sort order
  Future<void> updateSortOrder(List<Category> categories) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (int i = 0; i < categories.length; i++) {
      batch.update(
        'categories',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [categories[i].id],
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get category count for user
  Future<int> getCategoryCount(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery(
      'SELECT COUNT(*) as count FROM categories WHERE user_id = ?',
      [userId],
    );
    return results.first['count'] as int;
  }

  /// Check if user has categories (for checking if defaults need to be inserted)
  Future<bool> hasCategories(int userId) async {
    final count = await getCategoryCount(userId);
    return count > 0;
  }

  /// Get 'Others' category for a user (fallback category)
  Future<Category?> getOthersCategory(int userId) async {
    return await getCategoryByName(userId, 'Others');
  }
}
