import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../database/repositories/expense_repository.dart';
import '../config/constants.dart';

/// Provider for expense state management
class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _expenseRepository = ExpenseRepository();

  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = false;
  String? _error;

  // Current view state
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int? _selectedCategoryId;
  String _sourceFilter = 'ALL'; // ALL, MANUAL, AUTO

  // Summary data
  double _monthlyTotal = 0;
  List<Map<String, dynamic>> _categoryBreakdown = [];

  // Getters
  List<Expense> get expenses => _filteredExpenses;
  List<Expense> get allExpenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  int? get selectedCategoryId => _selectedCategoryId;
  String get sourceFilter => _sourceFilter;
  double get monthlyTotal => _monthlyTotal;
  List<Map<String, dynamic>> get categoryBreakdown => _categoryBreakdown;

  /// Load expenses for selected month
  Future<void> loadExpenses(int userId) async {
    _setLoading(true);
    _clearError();

    try {
      _expenses = await _expenseRepository.getExpensesByMonth(
        userId,
        _selectedMonth,
        _selectedYear,
      );
      await _loadMonthlyData(userId);
      _applyFilters();
    } catch (e) {
      _setError('Failed to load expenses: $e');
    }

    _setLoading(false);
  }

  /// Load monthly summary data
  Future<void> _loadMonthlyData(int userId) async {
    _monthlyTotal = await _expenseRepository.getTotalExpensesByMonth(
      userId,
      _selectedMonth,
      _selectedYear,
    );
    _categoryBreakdown = await _expenseRepository.getCategoryWiseTotal(
      userId,
      _selectedMonth,
      _selectedYear,
    );
  }

  /// Change selected month
  Future<void> setMonth(int userId, int month, int year) async {
    _selectedMonth = month;
    _selectedYear = year;
    await loadExpenses(userId);
  }

  /// Go to previous month
  Future<void> previousMonth(int userId) async {
    if (_selectedMonth == 1) {
      _selectedMonth = 12;
      _selectedYear--;
    } else {
      _selectedMonth--;
    }
    await loadExpenses(userId);
  }

  /// Go to next month
  Future<void> nextMonth(int userId) async {
    if (_selectedMonth == 12) {
      _selectedMonth = 1;
      _selectedYear++;
    } else {
      _selectedMonth++;
    }
    await loadExpenses(userId);
  }

  /// Add a new expense
  Future<bool> addExpense(Expense expense) async {
    _setLoading(true);
    _clearError();

    try {
      final id = await _expenseRepository.createExpense(expense);
      final newExpense = await _expenseRepository.getExpenseById(id);
      if (newExpense != null) {
        // Check if expense belongs to current view
        if (expense.date.month == _selectedMonth && expense.date.year == _selectedYear) {
          _expenses.insert(0, newExpense);
          _expenses.sort((a, b) => b.date.compareTo(a.date));
        }
        await _loadMonthlyData(expense.userId);
        _applyFilters();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add expense: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Update an expense
  Future<bool> updateExpense(Expense expense) async {
    _setLoading(true);
    _clearError();

    try {
      await _expenseRepository.updateExpense(expense);
      final updatedExpense = await _expenseRepository.getExpenseById(expense.id!);
      if (updatedExpense != null) {
        final index = _expenses.indexWhere((e) => e.id == expense.id);
        if (index != -1) {
          _expenses[index] = updatedExpense;
        }
        await _loadMonthlyData(expense.userId);
        _applyFilters();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update expense: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Delete an expense
  Future<bool> deleteExpense(int expenseId, int userId) async {
    _setLoading(true);
    _clearError();

    try {
      await _expenseRepository.deleteExpense(expenseId);
      _expenses.removeWhere((e) => e.id == expenseId);
      await _loadMonthlyData(userId);
      _applyFilters();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete expense: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Get expense by ID
  Future<Expense?> getExpenseById(int expenseId) async {
    return await _expenseRepository.getExpenseById(expenseId);
  }

  /// Get recent expenses for dashboard
  Future<List<Expense>> getRecentExpenses(int userId, {int limit = 5}) async {
    return await _expenseRepository.getRecentExpenses(userId, limit: limit);
  }

  // ============ Filtering ============

  /// Set category filter
  void setCategoryFilter(int? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
  }

  /// Set source filter (ALL, MANUAL, AUTO)
  void setSourceFilter(String filter) {
    _sourceFilter = filter;
    _applyFilters();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedCategoryId = null;
    _sourceFilter = 'ALL';
    _applyFilters();
  }

  /// Apply current filters
  void _applyFilters() {
    _filteredExpenses = _expenses.where((expense) {
      // Category filter
      if (_selectedCategoryId != null && expense.categoryId != _selectedCategoryId) {
        return false;
      }

      // Source filter
      if (_sourceFilter != 'ALL' && expense.source != _sourceFilter) {
        return false;
      }

      return true;
    }).toList();

    notifyListeners();
  }

  // ============ Grouped Data ============

  /// Get expenses grouped by date
  Map<String, List<Expense>> get expensesGroupedByDate {
    final grouped = <String, List<Expense>>{};

    for (final expense in _filteredExpenses) {
      final dateKey = expense.date.toIso8601String().split('T')[0];
      grouped.putIfAbsent(dateKey, () => []).add(expense);
    }

    return grouped;
  }

  /// Get total for a specific date
  double getTotalForDate(String dateKey) {
    final dayExpenses = expensesGroupedByDate[dateKey] ?? [];
    return dayExpenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  // ============ Statistics ============

  /// Get average daily expense for current month
  double get averageDailyExpense {
    if (_expenses.isEmpty) return 0;

    final now = DateTime.now();
    int daysInMonth;

    if (_selectedYear == now.year && _selectedMonth == now.month) {
      // Current month - use days elapsed
      daysInMonth = now.day;
    } else {
      // Past/future month - use total days
      daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    }

    return _monthlyTotal / daysInMonth;
  }

  /// Get expense count for current month
  int get expenseCount => _expenses.length;

  /// Get auto-detected expense count
  int get autoDetectedCount => _expenses.where((e) => e.source == ExpenseSource.AUTO).length;

  /// Get manual expense count
  int get manualCount => _expenses.where((e) => e.source == ExpenseSource.MANUAL).length;

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
