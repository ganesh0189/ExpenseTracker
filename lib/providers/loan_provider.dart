import 'package:flutter/foundation.dart';

import '../models/loan.dart';
import '../models/partial_payment.dart';
import '../database/repositories/loan_repository.dart';
import '../config/constants.dart';

/// Provider for loan state management
class LoanProvider extends ChangeNotifier {
  final LoanRepository _loanRepository = LoanRepository();

  List<Loan> _loans = [];
  List<Loan> _filteredLoans = [];
  bool _isLoading = false;
  String? _error;

  // Filter state
  String _typeFilter = 'ALL'; // ALL, LENT, BORROWED
  String _statusFilter = 'ALL'; // ALL, PENDING, SETTLED
  String _searchQuery = '';

  // Summary data
  double _totalLent = 0;
  double _totalBorrowed = 0;
  int _pendingLentCount = 0;
  int _pendingBorrowedCount = 0;

  // Getters
  List<Loan> get loans => _filteredLoans;
  List<Loan> get allLoans => _loans;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get typeFilter => _typeFilter;
  String get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;

  double get totalLent => _totalLent;
  double get totalBorrowed => _totalBorrowed;
  double get netBalance => _totalLent - _totalBorrowed;
  int get pendingLentCount => _pendingLentCount;
  int get pendingBorrowedCount => _pendingBorrowedCount;

  /// Load all loans for a user
  Future<void> loadLoans(int userId) async {
    _setLoading(true);
    _clearError();

    try {
      _loans = await _loanRepository.getAllLoans(userId);
      await _loadSummary(userId);
      _applyFilters();
    } catch (e) {
      _setError('Failed to load loans: $e');
    }

    _setLoading(false);
  }

  /// Load summary data
  Future<void> _loadSummary(int userId) async {
    _totalLent = await _loanRepository.getTotalLent(userId);
    _totalBorrowed = await _loanRepository.getTotalBorrowed(userId);
    _pendingLentCount = await _loanRepository.getPendingLoanCount(userId, LoanType.LENT);
    _pendingBorrowedCount = await _loanRepository.getPendingLoanCount(userId, LoanType.BORROWED);
  }

  /// Add a new loan
  Future<bool> addLoan(Loan loan) async {
    _setLoading(true);
    _clearError();

    try {
      final id = await _loanRepository.createLoan(loan);
      final newLoan = await _loanRepository.getLoanById(id);
      if (newLoan != null) {
        _loans.insert(0, newLoan);
        await _loadSummary(loan.userId);
        _applyFilters();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add loan: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Update a loan
  Future<bool> updateLoan(Loan loan) async {
    _setLoading(true);
    _clearError();

    try {
      await _loanRepository.updateLoan(loan);
      final updatedLoan = await _loanRepository.getLoanById(loan.id!);
      if (updatedLoan != null) {
        final index = _loans.indexWhere((l) => l.id == loan.id);
        if (index != -1) {
          _loans[index] = updatedLoan;
        }
        await _loadSummary(loan.userId);
        _applyFilters();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update loan: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Delete a loan
  Future<bool> deleteLoan(int loanId, int userId) async {
    _setLoading(true);
    _clearError();

    try {
      await _loanRepository.deleteLoan(loanId);
      _loans.removeWhere((l) => l.id == loanId);
      await _loadSummary(userId);
      _applyFilters();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete loan: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Settle a loan fully
  Future<bool> settleLoan(int loanId, int userId) async {
    _setLoading(true);
    _clearError();

    try {
      await _loanRepository.settleLoan(loanId, DateTime.now());
      final updatedLoan = await _loanRepository.getLoanById(loanId);
      if (updatedLoan != null) {
        final index = _loans.indexWhere((l) => l.id == loanId);
        if (index != -1) {
          _loans[index] = updatedLoan;
        }
        await _loadSummary(userId);
        _applyFilters();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to settle loan: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Add partial payment to a loan
  Future<bool> addPartialPayment(PartialPayment payment, int userId) async {
    _setLoading(true);
    _clearError();

    try {
      await _loanRepository.addPartialPayment(payment);
      final updatedLoan = await _loanRepository.getLoanById(payment.loanId);
      if (updatedLoan != null) {
        final index = _loans.indexWhere((l) => l.id == payment.loanId);
        if (index != -1) {
          _loans[index] = updatedLoan;
        }
        await _loadSummary(userId);
        _applyFilters();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add payment: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Get partial payments for a loan
  Future<List<PartialPayment>> getPartialPayments(int loanId) async {
    return await _loanRepository.getPartialPayments(loanId);
  }

  /// Get loan by ID
  Future<Loan?> getLoanById(int loanId) async {
    return await _loanRepository.getLoanById(loanId);
  }

  /// Get loans by friend
  Future<List<Loan>> getLoansByFriend(int userId, int friendId) async {
    return await _loanRepository.getLoansByFriend(userId, friendId);
  }

  /// Get overdue loans
  Future<List<Loan>> getOverdueLoans(int userId) async {
    return await _loanRepository.getOverdueLoans(userId);
  }

  // ============ Filtering ============

  /// Set type filter (ALL, LENT, BORROWED)
  void setTypeFilter(String filter) {
    _typeFilter = filter;
    _applyFilters();
  }

  /// Set status filter (ALL, PENDING, SETTLED)
  void setStatusFilter(String filter) {
    _statusFilter = filter;
    _applyFilters();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Clear all filters
  void clearFilters() {
    _typeFilter = 'ALL';
    _statusFilter = 'ALL';
    _searchQuery = '';
    _applyFilters();
  }

  /// Apply current filters to loans list
  void _applyFilters() {
    _filteredLoans = _loans.where((loan) {
      // Type filter
      if (_typeFilter != 'ALL' && loan.type != _typeFilter) {
        return false;
      }

      // Status filter
      if (_statusFilter == 'PENDING' && loan.isSettled) {
        return false;
      }
      if (_statusFilter == 'SETTLED' && !loan.isSettled) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final friendName = loan.friendName?.toLowerCase() ?? '';
        final description = loan.description?.toLowerCase() ?? '';
        if (!friendName.contains(query) && !description.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    notifyListeners();
  }

  // ============ Helpers ============

  /// Get lent loans only
  List<Loan> get lentLoans => _loans.where((l) => l.type == LoanType.LENT).toList();

  /// Get borrowed loans only
  List<Loan> get borrowedLoans => _loans.where((l) => l.type == LoanType.BORROWED).toList();

  /// Get pending loans only
  List<Loan> get pendingLoans => _loans.where((l) => !l.isSettled).toList();

  /// Get settled loans only
  List<Loan> get settledLoans => _loans.where((l) => l.isSettled).toList();

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
