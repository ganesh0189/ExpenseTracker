import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/monitored_app.dart';
import '../models/merchant_rule.dart';
import '../database/repositories/settings_repository.dart';
import '../database/repositories/monitored_app_repository.dart';
import '../database/repositories/merchant_rule_repository.dart';
import '../services/notification_service.dart';

/// Provider for app settings state management
class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _settingsRepository = SettingsRepository();
  final MonitoredAppRepository _monitoredAppRepository = MonitoredAppRepository();
  final MerchantRuleRepository _merchantRuleRepository = MerchantRuleRepository();

  // Theme
  ThemeMode _themeMode = ThemeMode.system;

  // Notification settings
  bool _autoDetectEnabled = false;
  bool _notificationListenerEnabled = false;
  List<MonitoredApp> _monitoredApps = [];

  // Budget
  double _monthlyBudget = DEFAULT_MONTHLY_BUDGET;

  // Merchant rules
  List<MerchantRule> _merchantRules = [];

  // Loading state
  bool _isLoading = false;
  String? _error;

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get autoDetectEnabled => _autoDetectEnabled;
  bool get notificationListenerEnabled => _notificationListenerEnabled;
  List<MonitoredApp> get monitoredApps => _monitoredApps;
  double get monthlyBudget => _monthlyBudget;
  List<MerchantRule> get merchantRules => _merchantRules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize settings
  Future<void> initialize() async {
    await _loadThemeMode();
    await _checkNotificationPermission();
  }

  /// Load settings for a user
  Future<void> loadSettings(int userId) async {
    _setLoading(true);
    _clearError();

    try {
      // Load auto-detect setting (defaults to false for new installs)
      final autoDetect = await _settingsRepository.getSetting(userId, KEY_AUTO_DETECT_ENABLED);
      _autoDetectEnabled = autoDetect == 'true';

      // Load monthly budget
      final budgetStr = await _settingsRepository.getSetting(userId, KEY_MONTHLY_BUDGET);
      _monthlyBudget = budgetStr != null ? double.tryParse(budgetStr) ?? DEFAULT_MONTHLY_BUDGET : DEFAULT_MONTHLY_BUDGET;

      // Load monitored apps
      _monitoredApps = await _monitoredAppRepository.getAllMonitoredApps(userId);

      // Load merchant rules
      _merchantRules = await _merchantRuleRepository.getAllRules(userId);

      // Check notification permission
      await _checkNotificationPermission();
    } catch (e) {
      _setError('Failed to load settings: $e');
    }

    _setLoading(false);
  }

  // ============ Theme Settings ============

  /// Load theme mode from preferences
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(KEY_THEME_MODE) ?? 'system';
    _themeMode = _parseThemeMode(themeStr);
    notifyListeners();
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_THEME_MODE, _themeModeToString(mode));
    notifyListeners();
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  // ============ Notification Settings ============

  /// Check notification listener permission
  Future<void> _checkNotificationPermission() async {
    _notificationListenerEnabled = await notificationService.isNotificationListenerEnabled();
    notifyListeners();
  }

  /// Refresh notification permission status
  Future<void> refreshNotificationPermission() async {
    await _checkNotificationPermission();
  }

  /// Open notification listener settings
  Future<void> openNotificationSettings() async {
    await notificationService.openNotificationListenerSettings();
  }

  /// Toggle auto-detect setting
  Future<void> setAutoDetectEnabled(int userId, bool enabled) async {
    _autoDetectEnabled = enabled;
    await _settingsRepository.setSetting(userId, KEY_AUTO_DETECT_ENABLED, enabled.toString());
    notifyListeners();
  }

  // ============ Budget Settings ============

  /// Set monthly budget
  Future<void> setMonthlyBudget(int userId, double budget) async {
    _monthlyBudget = budget;
    await _settingsRepository.setSetting(userId, KEY_MONTHLY_BUDGET, budget.toString());
    notifyListeners();
  }

  // ============ Monitored Apps ============

  /// Toggle monitored app
  Future<bool> toggleMonitoredApp(int appId, bool isEnabled) async {
    try {
      await _monitoredAppRepository.toggleAppEnabled(appId, isEnabled);
      final index = _monitoredApps.indexWhere((a) => a.id == appId);
      if (index != -1) {
        _monitoredApps[index] = _monitoredApps[index].copyWith(isEnabled: isEnabled);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update app setting: $e');
      return false;
    }
  }

  /// Add monitored app
  Future<bool> addMonitoredApp(MonitoredApp app) async {
    try {
      final id = await _monitoredAppRepository.createMonitoredApp(app);
      final newApp = await _monitoredAppRepository.getMonitoredAppById(id);
      if (newApp != null) {
        _monitoredApps.add(newApp);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to add app: $e');
      return false;
    }
  }

  /// Get enabled app package names
  List<String> get enabledAppPackages {
    return _monitoredApps
        .where((a) => a.isEnabled)
        .map((a) => a.packageName)
        .toList();
  }

  // ============ Merchant Rules ============

  /// Add merchant rule
  Future<bool> addMerchantRule(MerchantRule rule) async {
    try {
      // Check if pattern exists
      final exists = await _merchantRuleRepository.patternExists(rule.userId, rule.pattern);
      if (exists) {
        _setError('A rule with this pattern already exists');
        return false;
      }

      final id = await _merchantRuleRepository.createRule(rule);
      final newRule = await _merchantRuleRepository.getRuleById(id);
      if (newRule != null) {
        _merchantRules.add(newRule);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to add rule: $e');
      return false;
    }
  }

  /// Update merchant rule
  Future<bool> updateMerchantRule(MerchantRule rule) async {
    try {
      // Check if pattern exists (excluding current rule)
      final exists = await _merchantRuleRepository.patternExists(
        rule.userId,
        rule.pattern,
        excludeId: rule.id,
      );
      if (exists) {
        _setError('A rule with this pattern already exists');
        return false;
      }

      await _merchantRuleRepository.updateRule(rule);
      final updatedRule = await _merchantRuleRepository.getRuleById(rule.id!);
      if (updatedRule != null) {
        final index = _merchantRules.indexWhere((r) => r.id == rule.id);
        if (index != -1) {
          _merchantRules[index] = updatedRule;
          notifyListeners();
        }
      }
      return true;
    } catch (e) {
      _setError('Failed to update rule: $e');
      return false;
    }
  }

  /// Delete merchant rule
  Future<bool> deleteMerchantRule(int ruleId) async {
    try {
      await _merchantRuleRepository.deleteRule(ruleId);
      _merchantRules.removeWhere((r) => r.id == ruleId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete rule: $e');
      return false;
    }
  }

  // ============ Data Management ============

  /// Clear all expenses
  Future<bool> clearAllExpenses(int userId) async {
    try {
      await _settingsRepository.deleteAllExpenses(userId);
      return true;
    } catch (e) {
      _setError('Failed to clear expenses: $e');
      return false;
    }
  }

  /// Clear all loans
  Future<bool> clearAllLoans(int userId) async {
    try {
      await _settingsRepository.deleteAllLoans(userId);
      return true;
    } catch (e) {
      _setError('Failed to clear loans: $e');
      return false;
    }
  }

  /// Clear all user data (factory reset)
  Future<bool> clearAllData(int userId) async {
    try {
      await _settingsRepository.deleteAllUserData(userId);
      return true;
    } catch (e) {
      _setError('Failed to clear data: $e');
      return false;
    }
  }

  // Private helpers
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
