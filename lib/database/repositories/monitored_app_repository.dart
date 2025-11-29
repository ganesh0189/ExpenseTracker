import '../database_helper.dart';
import '../../models/monitored_app.dart';
import '../../config/constants.dart';

/// Repository for monitored app database operations
class MonitoredAppRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Create a new monitored app
  Future<int> createMonitoredApp(MonitoredApp app) async {
    final db = await _dbHelper.database;
    return await db.insert('monitored_apps', app.toMap());
  }

  /// Get all monitored apps for a user
  Future<List<MonitoredApp>> getAllMonitoredApps(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'monitored_apps',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'app_name ASC',
    );
    return results.map((map) => MonitoredApp.fromMap(map)).toList();
  }

  /// Get enabled monitored apps
  Future<List<MonitoredApp>> getEnabledMonitoredApps(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'monitored_apps',
      where: 'user_id = ? AND is_enabled = 1',
      whereArgs: [userId],
      orderBy: 'app_name ASC',
    );
    return results.map((map) => MonitoredApp.fromMap(map)).toList();
  }

  /// Get monitored app by ID
  Future<MonitoredApp?> getMonitoredAppById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'monitored_apps',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return MonitoredApp.fromMap(results.first);
  }

  /// Get monitored app by package name
  Future<MonitoredApp?> getMonitoredAppByPackage(int userId, String packageName) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'monitored_apps',
      where: 'user_id = ? AND package_name = ?',
      whereArgs: [userId, packageName],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return MonitoredApp.fromMap(results.first);
  }

  /// Update monitored app
  Future<int> updateMonitoredApp(MonitoredApp app) async {
    final db = await _dbHelper.database;
    return await db.update(
      'monitored_apps',
      app.toMap(),
      where: 'id = ?',
      whereArgs: [app.id],
    );
  }

  /// Toggle app enabled status
  Future<int> toggleAppEnabled(int id, bool isEnabled) async {
    final db = await _dbHelper.database;
    return await db.update(
      'monitored_apps',
      {'is_enabled': isEnabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete monitored app
  Future<int> deleteMonitoredApp(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'monitored_apps',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Check if package is monitored and enabled
  Future<bool> isPackageMonitored(int userId, String packageName) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'monitored_apps',
      where: 'user_id = ? AND package_name = ? AND is_enabled = 1',
      whereArgs: [userId, packageName],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Get list of enabled package names
  Future<List<String>> getEnabledPackageNames(int userId) async {
    final apps = await getEnabledMonitoredApps(userId);
    return apps.map((app) => app.packageName).toList();
  }

  /// Insert default monitored apps for a new user
  Future<void> insertDefaultMonitoredApps(int userId) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final entry in PAYMENT_APPS.entries) {
      batch.insert('monitored_apps', {
        'user_id': userId,
        'package_name': entry.key,
        'app_name': entry.value,
        'is_enabled': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    await batch.commit(noResult: true);
  }

  /// Check if user has monitored apps configured
  Future<bool> hasMonitoredApps(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery(
      'SELECT COUNT(*) as count FROM monitored_apps WHERE user_id = ?',
      [userId],
    );
    return (results.first['count'] as int) > 0;
  }
}
