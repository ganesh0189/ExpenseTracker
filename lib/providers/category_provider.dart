import 'package:flutter/foundation.dart' hide Category;

import '../models/category.dart';
import '../database/repositories/category_repository.dart';

/// Provider for category state management
class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _categoryRepository = CategoryRepository();

  List<Category> _categories = [];
  List<Category> _visibleCategories = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Category> get categories => _categories;
  List<Category> get visibleCategories => _visibleCategories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all categories for a user
  Future<void> loadCategories(int userId) async {
    _setLoading(true);
    _clearError();

    try {
      // Check if user has categories, if not insert defaults
      final hasCategories = await _categoryRepository.hasCategories(userId);
      if (!hasCategories) {
        await _categoryRepository.insertDefaultCategories(userId);
      }

      _categories = await _categoryRepository.getAllCategories(userId);
      _visibleCategories = _categories.where((c) => !c.isHidden).toList();
    } catch (e) {
      _setError('Failed to load categories: $e');
    }

    _setLoading(false);
  }

  /// Add a new category
  Future<bool> addCategory(Category category) async {
    _setLoading(true);
    _clearError();

    try {
      final id = await _categoryRepository.createCategory(category);
      final newCategory = await _categoryRepository.getCategoryById(id);
      if (newCategory != null) {
        _categories.add(newCategory);
        if (!newCategory.isHidden) {
          _visibleCategories.add(newCategory);
        }
        _sortCategories();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add category: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Update a category
  Future<bool> updateCategory(Category category) async {
    _setLoading(true);
    _clearError();

    try {
      await _categoryRepository.updateCategory(category);
      final updatedCategory = await _categoryRepository.getCategoryById(category.id!);
      if (updatedCategory != null) {
        final index = _categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          _categories[index] = updatedCategory;
        }
        _updateVisibleCategories();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update category: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Delete a category (only custom categories)
  Future<bool> deleteCategory(int categoryId) async {
    final category = _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => throw Exception('Category not found'),
    );

    if (category.isDefault) {
      _setError('Cannot delete default category');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _categoryRepository.deleteCategory(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      _visibleCategories.removeWhere((c) => c.id == categoryId);
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete category: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Hide a category
  Future<bool> hideCategory(int categoryId) async {
    _setLoading(true);
    _clearError();

    try {
      await _categoryRepository.hideCategory(categoryId);
      final index = _categories.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        _categories[index] = _categories[index].copyWith(isHidden: true);
        _updateVisibleCategories();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to hide category: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Show (unhide) a category
  Future<bool> showCategory(int categoryId) async {
    _setLoading(true);
    _clearError();

    try {
      await _categoryRepository.showCategory(categoryId);
      final index = _categories.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        _categories[index] = _categories[index].copyWith(isHidden: false);
        _updateVisibleCategories();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to show category: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Update category sort order
  Future<bool> updateSortOrder(List<Category> orderedCategories) async {
    _setLoading(true);
    _clearError();

    try {
      await _categoryRepository.updateSortOrder(orderedCategories);
      _categories = orderedCategories;
      _updateVisibleCategories();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update order: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Get category by ID
  Category? getCategoryById(int categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Get category by name
  Category? getCategoryByName(String name) {
    try {
      return _categories.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get 'Others' category
  Category? get othersCategory => getCategoryByName('Others');

  /// Get default categories only
  List<Category> get defaultCategories => _categories.where((c) => c.isDefault).toList();

  /// Get custom categories only
  List<Category> get customCategories => _categories.where((c) => !c.isDefault).toList();

  /// Get hidden categories
  List<Category> get hiddenCategories => _categories.where((c) => c.isHidden).toList();

  // Private helpers
  void _updateVisibleCategories() {
    _visibleCategories = _categories.where((c) => !c.isHidden).toList();
    notifyListeners();
  }

  void _sortCategories() {
    _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _updateVisibleCategories();
  }

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
