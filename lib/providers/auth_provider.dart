import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

/// Provider for authentication state management
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;
  AuthState _state = AuthState.initial;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AuthState get state => _state;
  bool get isLoggedIn => _user != null;
  int? get userId => _user?.id;

  /// Initialize auth state (call on app start)
  Future<void> initialize() async {
    _setLoading(true);
    _state = AuthState.checking;

    // Check if any user exists
    final hasUsers = await _authService.hasUsers();
    if (!hasUsers) {
      _state = AuthState.needsRegistration;
      _setLoading(false);
      return;
    }

    // Try to restore session
    final result = await _authService.checkSession();
    if (result.success) {
      _user = result.user;
      _state = AuthState.authenticated;
    } else {
      // Check if PIN login is available
      final hasPin = await _authService.hasPinEnabled();
      _state = hasPin ? AuthState.needsPinLogin : AuthState.needsLogin;
    }

    _setLoading(false);
  }

  /// Register a new user
  Future<bool> register({
    required String fullName,
    required String username,
    required String password,
    String? pin,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.register(
      fullName: fullName,
      username: username,
      password: password,
      pin: pin,
    );

    if (result.success) {
      _user = result.user;
      _state = AuthState.authenticated;
      _setLoading(false);
      return true;
    } else {
      _setError(result.error ?? 'Registration failed');
      _setLoading(false);
      return false;
    }
  }

  /// Login with username and password
  Future<bool> login({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.login(
      username: username,
      password: password,
      rememberMe: rememberMe,
    );

    if (result.success) {
      _user = result.user;
      _state = AuthState.authenticated;
      _setLoading(false);
      return true;
    } else {
      _setError(result.error ?? 'Login failed');
      _setLoading(false);
      return false;
    }
  }

  /// Login with PIN
  Future<bool> loginWithPin(String pin) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.loginWithPin(pin);

    if (result.success) {
      _user = result.user;
      _state = AuthState.authenticated;
      _setLoading(false);
      return true;
    } else {
      _setError(result.error ?? 'Invalid PIN');
      _setLoading(false);
      return false;
    }
  }

  /// Logout (keeps user data for PIN login)
  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    _user = null;

    final hasPin = await _authService.hasPinEnabled();
    _state = hasPin ? AuthState.needsPinLogin : AuthState.needsLogin;

    _setLoading(false);
  }

  /// Full logout (clears all session data)
  Future<void> fullLogout() async {
    _setLoading(true);
    await _authService.fullLogout();
    _user = null;
    _state = AuthState.needsLogin;
    _setLoading(false);
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (result.success) {
      _user = result.user;
      _setLoading(false);
      return true;
    } else {
      _setError(result.error ?? 'Failed to change password');
      _setLoading(false);
      return false;
    }
  }

  /// Set PIN
  Future<bool> setPin(String pin) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.setPin(pin);

    if (result.success) {
      _user = result.user;
      _setLoading(false);
      return true;
    } else {
      _setError(result.error ?? 'Failed to set PIN');
      _setLoading(false);
      return false;
    }
  }

  /// Remove PIN
  Future<bool> removePin() async {
    _setLoading(true);
    _clearError();

    final result = await _authService.removePin();

    if (result.success) {
      _user = result.user;
      _setLoading(false);
      return true;
    } else {
      _setError(result.error ?? 'Failed to remove PIN');
      _setLoading(false);
      return false;
    }
  }

  /// Verify password (for sensitive operations)
  Future<bool> verifyPassword(String password) async {
    return await _authService.verifyPassword(password);
  }

  /// Verify PIN (for sensitive operations)
  Future<bool> verifyPin(String pin) async {
    return await _authService.verifyPin(pin);
  }

  /// Update profile
  Future<bool> updateProfile({String? fullName}) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.updateProfile(fullName: fullName);

    if (result.success) {
      _user = result.user;
      _setLoading(false);
      return true;
    } else {
      _setError(result.error ?? 'Failed to update profile');
      _setLoading(false);
      return false;
    }
  }

  /// Get saved username for display on login screen
  Future<String?> getSavedUsername() async {
    return await _authService.getSavedUsername();
  }

  /// Check if PIN is enabled for current user
  bool get hasPinEnabled => _user?.hasPin ?? false;

  /// Refresh user data
  Future<void> refreshUser() async {
    await _authService.refreshCurrentUser();
    _user = _authService.currentUser;
    notifyListeners();
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

/// Authentication state enum
enum AuthState {
  initial,
  checking,
  needsRegistration,
  needsLogin,
  needsPinLogin,
  authenticated,
}
