/// App setting model for user preferences
class AppSetting {
  final int? id;
  final int userId;
  final String key;
  final String value;

  AppSetting({
    this.id,
    required this.userId,
    required this.key,
    required this.value,
  });

  /// Create AppSetting from database map
  factory AppSetting.fromMap(Map<String, dynamic> map) {
    return AppSetting(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      key: map['key'] as String,
      value: map['value'] as String,
    );
  }

  /// Convert AppSetting to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'key': key,
      'value': value,
    };
  }

  /// Create a copy with updated fields
  AppSetting copyWith({
    int? id,
    int? userId,
    String? key,
    String? value,
  }) {
    return AppSetting(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  String toString() {
    return 'AppSetting(id: $id, key: $key, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSetting && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Known setting keys
class SettingKeys {
  static const String themeMode = 'theme_mode';
  static const String autoDetectEnabled = 'auto_detect_enabled';
  static const String budgetAlertThreshold = 'budget_alert_threshold';
  static const String dateFormat = 'date_format';
  static const String showCents = 'show_cents';
}
