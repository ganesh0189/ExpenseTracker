import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../database/repositories/user_repository.dart';
import '../database/repositories/category_repository.dart';
import '../database/repositories/monitored_app_repository.dart';
import '../database/repositories/merchant_rule_repository.dart';
import '../models/user.dart';

/// Service for authentication and session management
class AuthService {
  final UserRepository _userRepository = UserRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final MonitoredAppRepository _monitoredAppRepository = MonitoredAppRepository();
  final MerchantRuleRepository _merchantRuleRepository = MerchantRuleRepository();

  User? _currentUser;

  /// Get current logged-in user
  User? get currentUser => _currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Hash password using SHA-256
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Register a new user
  Future<AuthResult> register({
    required String fullName,
    required String username,
    required String password,
    String? pin,
  }) async {
    try {
      final normalizedUsername = username.trim().toLowerCase();

      // Check if username already exists
      if (await _userRepository.usernameExists(normalizedUsername)) {
        return AuthResult.failure('Username already exists. Please login instead.');
      }

      // Create user
      final user = User(
        fullName: fullName.trim(),
        username: normalizedUsername,
        passwordHash: hashPassword(password),
        pinHash: pin != null ? hashPassword(pin) : null,
      );

      final userId = await _userRepository.createUser(user);

      // Get the created user
      final createdUser = await _userRepository.getUserById(userId);
      if (createdUser == null) {
        return AuthResult.failure('Failed to create user');
      }

      // Insert default data - wrap in try-catch to not fail registration
      try {
        // Insert default categories
        await _categoryRepository.insertDefaultCategories(userId);

        // Insert default monitored apps
        await _monitoredAppRepository.insertDefaultMonitoredApps(userId);

        // Get category map for merchant rules
        final categories = await _categoryRepository.getAllCategories(userId);
        final categoryMap = <String, int>{};
        for (final cat in categories) {
          categoryMap[cat.name] = cat.id!;
        }

        // Insert default merchant rules
        await _merchantRuleRepository.insertDefaultRules(userId, categoryMap);
      } catch (setupError) {
        // Log but don't fail registration - user can add categories manually
        print('Warning: Failed to insert default data: $setupError');
      }

      // Save session
      await _saveSession(createdUser, rememberMe: true);
      _currentUser = createdUser;

      return AuthResult.success(createdUser);
    } catch (e) {
      // Check for duplicate username error
      if (e.toString().contains('UNIQUE constraint failed') ||
          e.toString().contains('username')) {
        return AuthResult.failure('Username already taken. Please choose a different username or login with existing account.');
      }
      return AuthResult.failure('Registration failed. Please try again.');
    }
  }

  /// Login with username and password
  Future<AuthResult> login({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final passwordHash = hashPassword(password);
      final user = await _userRepository.validateCredentials(
        username.trim().toLowerCase(),
        passwordHash,
      );

      if (user == null) {
        return AuthResult.failure('Invalid username or password');
      }

      await _saveSession(user, rememberMe: rememberMe);
      _currentUser = user;

      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('Login failed: ${e.toString()}');
    }
  }

  /// Login with PIN
  Future<AuthResult> loginWithPin(String pin) async {
    try {
      // Get saved user ID from preferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(KEY_USER_ID);

      if (userId == null) {
        return AuthResult.failure('No user found. Please login with password.');
      }

      final pinHash = hashPassword(pin);
      final user = await _userRepository.validatePin(userId, pinHash);

      if (user == null) {
        return AuthResult.failure('Invalid PIN');
      }

      await _saveSession(user, rememberMe: true);
      _currentUser = user;

      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('PIN login failed: ${e.toString()}');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_IS_LOGGED_IN);
    // Keep user ID and username for PIN login
    _currentUser = null;
  }

  /// Full logout (clear all session data)
  Future<void> fullLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_IS_LOGGED_IN);
    await prefs.remove(KEY_USER_ID);
    await prefs.remove(KEY_USERNAME);
    await prefs.remove(KEY_REMEMBER_ME);
    _currentUser = null;
  }

  /// Check and restore session on app start
  Future<AuthResult> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(KEY_IS_LOGGED_IN) ?? false;
      final rememberMe = prefs.getBool(KEY_REMEMBER_ME) ?? false;
      final userId = prefs.getInt(KEY_USER_ID);

      if (!isLoggedIn || !rememberMe || userId == null) {
        return AuthResult.failure('No active session');
      }

      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        await fullLogout();
        return AuthResult.failure('User not found');
      }

      _currentUser = user;
      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('Session check failed: ${e.toString()}');
    }
  }

  /// Check if any user exists (for first-time setup)
  Future<bool> hasUsers() async {
    return await _userRepository.hasUsers();
  }

  /// Check if saved user has PIN enabled
  Future<bool> hasPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(KEY_USER_ID);

    if (userId == null) return false;

    final user = await _userRepository.getUserById(userId);
    return user?.hasPin ?? false;
  }

  /// Get saved username for display
  Future<String?> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_USERNAME);
  }

  /// Change password
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      return AuthResult.failure('Not logged in');
    }

    try {
      // Verify current password
      final currentHash = hashPassword(currentPassword);
      if (currentHash != _currentUser!.passwordHash) {
        return AuthResult.failure('Current password is incorrect');
      }

      // Update password
      final newHash = hashPassword(newPassword);
      await _userRepository.updatePassword(_currentUser!.id!, newHash);

      // Refresh current user
      final updatedUser = await _userRepository.getUserById(_currentUser!.id!);
      if (updatedUser != null) {
        _currentUser = updatedUser;
      }

      return AuthResult.success(_currentUser!);
    } catch (e) {
      return AuthResult.failure('Failed to change password: ${e.toString()}');
    }
  }

  /// Set or change PIN
  Future<AuthResult> setPin(String pin) async {
    if (_currentUser == null) {
      return AuthResult.failure('Not logged in');
    }

    try {
      final pinHash = hashPassword(pin);
      await _userRepository.updatePin(_currentUser!.id!, pinHash);

      // Refresh current user
      final updatedUser = await _userRepository.getUserById(_currentUser!.id!);
      if (updatedUser != null) {
        _currentUser = updatedUser;
      }

      return AuthResult.success(_currentUser!);
    } catch (e) {
      return AuthResult.failure('Failed to set PIN: ${e.toString()}');
    }
  }

  /// Remove PIN
  Future<AuthResult> removePin() async {
    if (_currentUser == null) {
      return AuthResult.failure('Not logged in');
    }

    try {
      await _userRepository.updatePin(_currentUser!.id!, null);

      // Refresh current user
      final updatedUser = await _userRepository.getUserById(_currentUser!.id!);
      if (updatedUser != null) {
        _currentUser = updatedUser;
      }

      return AuthResult.success(_currentUser!);
    } catch (e) {
      return AuthResult.failure('Failed to remove PIN: ${e.toString()}');
    }
  }

  /// Verify PIN (for sensitive operations)
  Future<bool> verifyPin(String pin) async {
    if (_currentUser == null || !_currentUser!.hasPin) {
      return false;
    }

    final pinHash = hashPassword(pin);
    return pinHash == _currentUser!.pinHash;
  }

  /// Verify password (for sensitive operations)
  Future<bool> verifyPassword(String password) async {
    if (_currentUser == null) {
      return false;
    }

    final passwordHash = hashPassword(password);
    return passwordHash == _currentUser!.passwordHash;
  }

  /// Update user profile
  Future<AuthResult> updateProfile({String? fullName}) async {
    if (_currentUser == null) {
      return AuthResult.failure('Not logged in');
    }

    try {
      final updatedUser = _currentUser!.copyWith(
        fullName: fullName ?? _currentUser!.fullName,
      );

      await _userRepository.updateUser(updatedUser);
      _currentUser = await _userRepository.getUserById(_currentUser!.id!);

      return AuthResult.success(_currentUser!);
    } catch (e) {
      return AuthResult.failure('Failed to update profile: ${e.toString()}');
    }
  }

  /// Save session to SharedPreferences
  Future<void> _saveSession(User user, {required bool rememberMe}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(KEY_IS_LOGGED_IN, true);
    await prefs.setInt(KEY_USER_ID, user.id!);
    await prefs.setString(KEY_USERNAME, user.username);
    await prefs.setBool(KEY_REMEMBER_ME, rememberMe);
  }

  /// Refresh current user data from database
  Future<void> refreshCurrentUser() async {
    if (_currentUser?.id != null) {
      _currentUser = await _userRepository.getUserById(_currentUser!.id!);
    }
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool success;
  final User? user;
  final String? error;

  AuthResult._({
    required this.success,
    this.user,
    this.error,
  });

  factory AuthResult.success(User user) {
    return AuthResult._(success: true, user: user);
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(success: false, error: error);
  }
}
