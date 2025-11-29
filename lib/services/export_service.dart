import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../database/repositories/expense_repository.dart';
import '../database/repositories/loan_repository.dart';
import '../database/repositories/friend_repository.dart';
import '../database/repositories/category_repository.dart';
import '../models/expense.dart';
import '../models/loan.dart';
import '../models/friend.dart';
import '../models/category.dart';

/// Service for exporting data to CSV and JSON formats
class ExportService {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final LoanRepository _loanRepository = LoanRepository();
  final FriendRepository _friendRepository = FriendRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();

  /// Get the downloads directory path
  Future<String> get _downloadsPath async {
    if (Platform.isAndroid) {
      // Try to get external storage downloads folder
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        // Navigate to Downloads folder
        final downloadsPath = '${directory.parent.parent.parent.parent.path}/Download';
        final downloadsDir = Directory(downloadsPath);
        if (await downloadsDir.exists()) {
          return downloadsPath;
        }
      }
      // Fallback to app documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      return docsDir.path;
    }
    final docsDir = await getApplicationDocumentsDirectory();
    return docsDir.path;
  }

  /// Generate timestamp string for filenames
  String _getTimestamp() {
    return DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  }

  // ============ Export Expenses ============

  /// Export all expenses to CSV
  Future<ExportResult> exportExpensesToCsv(int userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      List<Expense> expenses;

      if (startDate != null && endDate != null) {
        expenses = await _expenseRepository.getExpensesByDateRange(userId, startDate, endDate);
      } else {
        expenses = await _expenseRepository.getAllExpenses(userId);
      }

      if (expenses.isEmpty) {
        return ExportResult.failure('No expenses to export');
      }

      final csvContent = _expensesToCsv(expenses);
      final fileName = 'expenses_${_getTimestamp()}.csv';
      final filePath = await _saveFile(fileName, csvContent);

      return ExportResult.success(filePath, expenses.length);
    } catch (e) {
      return ExportResult.failure('Failed to export expenses: $e');
    }
  }

  /// Convert expenses to CSV format
  String _expensesToCsv(List<Expense> expenses) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Date,Time,Category,Amount,Merchant,Description,Source');

    // Data rows
    for (final expense in expenses) {
      final date = DateFormat('yyyy-MM-dd').format(expense.date);
      final time = expense.time ?? '';
      final category = _escapeCsv(expense.categoryName ?? 'Unknown');
      final amount = expense.amount.toStringAsFixed(2);
      final merchant = _escapeCsv(expense.merchant ?? '');
      final description = _escapeCsv(expense.description ?? '');
      final source = expense.source;

      buffer.writeln('$date,$time,$category,$amount,$merchant,$description,$source');
    }

    return buffer.toString();
  }

  // ============ Export Loans ============

  /// Export all loans to CSV
  Future<ExportResult> exportLoansToCsv(int userId) async {
    try {
      final loans = await _loanRepository.getAllLoans(userId);

      if (loans.isEmpty) {
        return ExportResult.failure('No loans to export');
      }

      final csvContent = _loansToCsv(loans);
      final fileName = 'loans_${_getTimestamp()}.csv';
      final filePath = await _saveFile(fileName, csvContent);

      return ExportResult.success(filePath, loans.length);
    } catch (e) {
      return ExportResult.failure('Failed to export loans: $e');
    }
  }

  /// Convert loans to CSV format
  String _loansToCsv(List<Loan> loans) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Date,Type,Friend,Amount,Remaining,Due Date,Status,Description');

    // Data rows
    for (final loan in loans) {
      final date = DateFormat('yyyy-MM-dd').format(loan.date);
      final type = loan.type;
      final friend = _escapeCsv(loan.friendName ?? 'Unknown');
      final amount = loan.amount.toStringAsFixed(2);
      final remaining = loan.remainingAmount.toStringAsFixed(2);
      final dueDate = loan.dueDate != null ? DateFormat('yyyy-MM-dd').format(loan.dueDate!) : '';
      final status = loan.isSettled ? 'Settled' : 'Pending';
      final description = _escapeCsv(loan.description ?? '');

      buffer.writeln('$date,$type,$friend,$amount,$remaining,$dueDate,$status,$description');
    }

    return buffer.toString();
  }

  // ============ Export All Data (JSON) ============

  /// Export all user data to JSON
  Future<ExportResult> exportAllDataToJson(int userId) async {
    try {
      // Fetch all data
      final expenses = await _expenseRepository.getAllExpenses(userId);
      final loans = await _loanRepository.getAllLoans(userId);
      final friends = await _friendRepository.getAllFriends(userId);
      final categories = await _categoryRepository.getAllCategories(userId);

      final data = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        'categories': categories.map(_categoryToMap).toList(),
        'friends': friends.map(_friendToMap).toList(),
        'loans': loans.map(_loanToMap).toList(),
        'expenses': expenses.map(_expenseToMap).toList(),
        'summary': {
          'totalCategories': categories.length,
          'totalFriends': friends.length,
          'totalLoans': loans.length,
          'totalExpenses': expenses.length,
          'totalExpenseAmount': expenses.fold<double>(0, (sum, e) => sum + e.amount),
          'totalLentAmount': loans.where((l) => l.type == 'LENT').fold<double>(0, (sum, l) => sum + l.amount),
          'totalBorrowedAmount': loans.where((l) => l.type == 'BORROWED').fold<double>(0, (sum, l) => sum + l.amount),
        },
      };

      final jsonContent = const JsonEncoder.withIndent('  ').convert(data);
      final fileName = 'money_tracker_backup_${_getTimestamp()}.json';
      final filePath = await _saveFile(fileName, jsonContent);

      final totalRecords = categories.length + friends.length + loans.length + expenses.length;
      return ExportResult.success(filePath, totalRecords);
    } catch (e) {
      return ExportResult.failure('Failed to export data: $e');
    }
  }

  /// Convert category to map for JSON
  Map<String, dynamic> _categoryToMap(Category category) {
    return {
      'name': category.name,
      'icon': category.icon,
      'color': category.color,
      'isDefault': category.isDefault,
    };
  }

  /// Convert friend to map for JSON
  Map<String, dynamic> _friendToMap(Friend friend) {
    return {
      'name': friend.name,
      'phone': friend.phone,
      'email': friend.email,
      'notes': friend.notes,
      'createdAt': friend.createdAt.toIso8601String(),
    };
  }

  /// Convert loan to map for JSON
  Map<String, dynamic> _loanToMap(Loan loan) {
    return {
      'type': loan.type,
      'friendName': loan.friendName,
      'amount': loan.amount,
      'remainingAmount': loan.remainingAmount,
      'date': loan.date.toIso8601String(),
      'dueDate': loan.dueDate?.toIso8601String(),
      'isSettled': loan.isSettled,
      'settledDate': loan.settledDate?.toIso8601String(),
      'description': loan.description,
      'createdAt': loan.createdAt.toIso8601String(),
    };
  }

  /// Convert expense to map for JSON
  Map<String, dynamic> _expenseToMap(Expense expense) {
    return {
      'categoryName': expense.categoryName,
      'amount': expense.amount,
      'merchant': expense.merchant,
      'description': expense.description,
      'date': expense.date.toIso8601String(),
      'time': expense.time,
      'source': expense.source,
      'createdAt': expense.createdAt.toIso8601String(),
    };
  }

  // ============ Helper Methods ============

  /// Save content to file and return the file path
  Future<String> _saveFile(String fileName, String content) async {
    final path = await _downloadsPath;
    final file = File('$path/$fileName');
    await file.writeAsString(content);
    return file.path;
  }

  /// Escape CSV special characters
  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Get file size in human-readable format
  String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Result class for export operations
class ExportResult {
  final bool success;
  final String? filePath;
  final int? recordCount;
  final String? error;

  ExportResult._({
    required this.success,
    this.filePath,
    this.recordCount,
    this.error,
  });

  factory ExportResult.success(String filePath, int recordCount) {
    return ExportResult._(
      success: true,
      filePath: filePath,
      recordCount: recordCount,
    );
  }

  factory ExportResult.failure(String error) {
    return ExportResult._(
      success: false,
      error: error,
    );
  }

  /// Get the filename from the full path
  String? get fileName {
    if (filePath == null) return null;
    return filePath!.split('/').last;
  }
}
