/// Monitored app model for notification tracking settings
class MonitoredApp {
  final int? id;
  final int userId;
  final String packageName;
  final String appName;
  final bool isEnabled;
  final DateTime createdAt;

  MonitoredApp({
    this.id,
    required this.userId,
    required this.packageName,
    required this.appName,
    this.isEnabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create MonitoredApp from database map
  factory MonitoredApp.fromMap(Map<String, dynamic> map) {
    return MonitoredApp(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String,
      isEnabled: (map['is_enabled'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert MonitoredApp to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'package_name': packageName,
      'app_name': appName,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  MonitoredApp copyWith({
    int? id,
    int? userId,
    String? packageName,
    String? appName,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return MonitoredApp(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'MonitoredApp(id: $id, appName: $appName, isEnabled: $isEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonitoredApp && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
