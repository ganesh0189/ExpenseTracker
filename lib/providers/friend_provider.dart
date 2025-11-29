import 'package:flutter/foundation.dart';

import '../models/friend.dart';
import '../database/repositories/friend_repository.dart';

/// Provider for friend state management
class FriendProvider extends ChangeNotifier {
  final FriendRepository _friendRepository = FriendRepository();

  List<Friend> _friends = [];
  List<Friend> _filteredFriends = [];
  List<Map<String, dynamic>> _friendsWithBalances = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Getters
  List<Friend> get friends => _filteredFriends;
  List<Friend> get allFriends => _friends;
  List<Map<String, dynamic>> get friendsWithBalances => _friendsWithBalances;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get friendCount => _friends.length;

  /// Load all friends for a user
  Future<void> loadFriends(int userId) async {
    _setLoading(true);
    _clearError();

    try {
      _friends = await _friendRepository.getAllFriends(userId);
      _friendsWithBalances = await _friendRepository.getAllFriendsWithBalances(userId);
      _applyFilters();
    } catch (e) {
      _setError('Failed to load friends: $e');
    }

    _setLoading(false);
  }

  /// Add a new friend
  Future<int?> addFriend(Friend friend) async {
    _setLoading(true);
    _clearError();

    try {
      // Check if name already exists
      final exists = await _friendRepository.friendNameExists(friend.userId, friend.name);
      if (exists) {
        _setError('A friend with this name already exists');
        _setLoading(false);
        return null;
      }

      final id = await _friendRepository.createFriend(friend);
      final newFriend = await _friendRepository.getFriendById(id);
      if (newFriend != null) {
        _friends.add(newFriend);
        _friends.sort((a, b) => a.name.compareTo(b.name));

        // Refresh balances
        _friendsWithBalances = await _friendRepository.getAllFriendsWithBalances(friend.userId);
        _applyFilters();
      }
      _setLoading(false);
      return id;
    } catch (e) {
      _setError('Failed to add friend: $e');
      _setLoading(false);
      return null;
    }
  }

  /// Update a friend
  Future<bool> updateFriend(Friend friend) async {
    _setLoading(true);
    _clearError();

    try {
      // Check if name already exists (excluding current friend)
      final exists = await _friendRepository.friendNameExists(
        friend.userId,
        friend.name,
        excludeId: friend.id,
      );
      if (exists) {
        _setError('A friend with this name already exists');
        _setLoading(false);
        return false;
      }

      await _friendRepository.updateFriend(friend);
      final updatedFriend = await _friendRepository.getFriendById(friend.id!);
      if (updatedFriend != null) {
        final index = _friends.indexWhere((f) => f.id == friend.id);
        if (index != -1) {
          _friends[index] = updatedFriend;
        }
        _friends.sort((a, b) => a.name.compareTo(b.name));

        // Refresh balances
        _friendsWithBalances = await _friendRepository.getAllFriendsWithBalances(friend.userId);
        _applyFilters();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update friend: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Delete a friend
  Future<bool> deleteFriend(int friendId, int userId) async {
    _setLoading(true);
    _clearError();

    try {
      await _friendRepository.deleteFriend(friendId);
      _friends.removeWhere((f) => f.id == friendId);
      _friendsWithBalances.removeWhere((f) => f['id'] == friendId);
      _applyFilters();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete friend: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Get friend by ID
  Friend? getFriendById(int friendId) {
    try {
      return _friends.firstWhere((f) => f.id == friendId);
    } catch (e) {
      return null;
    }
  }

  /// Get friend with balance info
  Future<Map<String, dynamic>?> getFriendWithBalance(int friendId, int userId) async {
    return await _friendRepository.getFriendWithBalance(friendId, userId);
  }

  // ============ Search & Filter ============

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
  }

  /// Apply search filter
  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredFriends = List.from(_friends);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredFriends = _friends.where((friend) {
        return friend.name.toLowerCase().contains(query) ||
            (friend.phone?.contains(query) ?? false) ||
            (friend.email?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  // ============ Balance Helpers ============

  /// Get balance for a specific friend
  Map<String, double> getBalanceForFriend(int friendId) {
    final friendData = _friendsWithBalances.firstWhere(
      (f) => f['id'] == friendId,
      orElse: () => {'to_receive': 0.0, 'to_pay': 0.0},
    );

    return {
      'toReceive': (friendData['to_receive'] as num?)?.toDouble() ?? 0.0,
      'toPay': (friendData['to_pay'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// Get net balance for a friend (positive = they owe you, negative = you owe them)
  double getNetBalanceForFriend(int friendId) {
    final balance = getBalanceForFriend(friendId);
    return balance['toReceive']! - balance['toPay']!;
  }

  /// Get friends who owe you money
  List<Map<String, dynamic>> get friendsWhoOweYou {
    return _friendsWithBalances.where((f) {
      final toReceive = (f['to_receive'] as num?)?.toDouble() ?? 0.0;
      return toReceive > 0;
    }).toList();
  }

  /// Get friends you owe money to
  List<Map<String, dynamic>> get friendsYouOwe {
    return _friendsWithBalances.where((f) {
      final toPay = (f['to_pay'] as num?)?.toDouble() ?? 0.0;
      return toPay > 0;
    }).toList();
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
