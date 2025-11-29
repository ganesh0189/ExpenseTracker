import '../database_helper.dart';
import '../../models/friend.dart';

/// Repository for friend database operations
class FriendRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Create a new friend
  Future<int> createFriend(Friend friend) async {
    final db = await _dbHelper.database;
    return await db.insert('friends', friend.toMap());
  }

  /// Get all friends for a user
  Future<List<Friend>> getAllFriends(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'friends',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return results.map((map) => Friend.fromMap(map)).toList();
  }

  /// Get friend by ID
  Future<Friend?> getFriendById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'friends',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Friend.fromMap(results.first);
  }

  /// Update friend
  Future<int> updateFriend(Friend friend) async {
    final db = await _dbHelper.database;
    return await db.update(
      'friends',
      friend.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [friend.id],
    );
  }

  /// Delete friend
  Future<int> deleteFriend(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'friends',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Search friends by name
  Future<List<Friend>> searchFriends(int userId, String query) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'friends',
      where: 'user_id = ? AND name LIKE ?',
      whereArgs: [userId, '%$query%'],
      orderBy: 'name ASC',
    );
    return results.map((map) => Friend.fromMap(map)).toList();
  }

  /// Get friend with loan balance
  Future<Map<String, dynamic>?> getFriendWithBalance(int friendId, int userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT
        f.*,
        COALESCE(SUM(CASE WHEN l.type = 'LENT' AND l.is_settled = 0 THEN l.remaining_amount ELSE 0 END), 0) as to_receive,
        COALESCE(SUM(CASE WHEN l.type = 'BORROWED' AND l.is_settled = 0 THEN l.remaining_amount ELSE 0 END), 0) as to_pay
      FROM friends f
      LEFT JOIN loans l ON f.id = l.friend_id AND l.user_id = ?
      WHERE f.id = ?
      GROUP BY f.id
    ''', [userId, friendId]);

    if (results.isEmpty) return null;
    return results.first;
  }

  /// Get all friends with their loan balances
  Future<List<Map<String, dynamic>>> getAllFriendsWithBalances(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT
        f.*,
        COALESCE(SUM(CASE WHEN l.type = 'LENT' AND l.is_settled = 0 THEN l.remaining_amount ELSE 0 END), 0) as to_receive,
        COALESCE(SUM(CASE WHEN l.type = 'BORROWED' AND l.is_settled = 0 THEN l.remaining_amount ELSE 0 END), 0) as to_pay
      FROM friends f
      LEFT JOIN loans l ON f.id = l.friend_id AND l.user_id = ?
      WHERE f.user_id = ?
      GROUP BY f.id
      ORDER BY f.name ASC
    ''', [userId, userId]);

    return results;
  }

  /// Check if friend name exists for user
  Future<bool> friendNameExists(int userId, String name, {int? excludeId}) async {
    final db = await _dbHelper.database;
    String where = 'user_id = ? AND LOWER(name) = LOWER(?)';
    List<dynamic> whereArgs = [userId, name];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final results = await db.query(
      'friends',
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Get friend count for user
  Future<int> getFriendCount(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery(
      'SELECT COUNT(*) as count FROM friends WHERE user_id = ?',
      [userId],
    );
    return results.first['count'] as int;
  }
}
