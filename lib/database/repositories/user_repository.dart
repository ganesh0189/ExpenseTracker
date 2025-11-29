import '../database_helper.dart';
import '../../models/user.dart';

/// Repository for user database operations
class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Create a new user
  Future<int> createUser(User user) async {
    final db = await _dbHelper.database;
    return await db.insert('users', user.toMap());
  }

  /// Get user by username
  Future<User?> getUserByUsername(String username) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  /// Get user by ID
  Future<User?> getUserById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  /// Update user
  Future<int> updateUser(User user) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      user.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Delete user
  Future<int> deleteUser(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Validate user credentials
  Future<User?> validateCredentials(String username, String passwordHash) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, passwordHash],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  /// Validate PIN
  Future<User?> validatePin(int userId, String pinHash) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ? AND pin_hash = ?',
      whereArgs: [userId, pinHash],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  /// Check if username exists
  Future<bool> usernameExists(String username) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Update password
  Future<int> updatePassword(int userId, String newPasswordHash) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      {
        'password_hash': newPasswordHash,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Update PIN
  Future<int> updatePin(int userId, String? newPinHash) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      {
        'pin_hash': newPinHash,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Update monthly budget
  Future<int> updateMonthlyBudget(int userId, double budget) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      {
        'monthly_budget': budget,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Get all users (for debugging)
  Future<List<User>> getAllUsers() async {
    final db = await _dbHelper.database;
    final results = await db.query('users');
    return results.map((map) => User.fromMap(map)).toList();
  }

  /// Check if any user exists
  Future<bool> hasUsers() async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    final count = results.first['count'] as int;
    return count > 0;
  }
}
