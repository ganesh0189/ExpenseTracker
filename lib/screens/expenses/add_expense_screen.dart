import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/themes.dart';
import '../../models/expense.dart';
import '../../models/category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../utils/validators.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/common.dart';

class AddExpenseScreen extends StatefulWidget {
  final int? editExpenseId;

  const AddExpenseScreen({super.key, this.editExpenseId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();

  Category? _selectedCategory;
  DateTime _transactionDate = DateTime.now();
  TimeOfDay _transactionTime = TimeOfDay.now();
  bool _isEditing = false;
  Expense? _existingExpense;
  final _customCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    // Load categories first
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId != null) {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      try {
        await categoryProvider.loadCategories(userId);
      } catch (e) {
        debugPrint('Error loading categories: $e');
      }
    }

    if (!mounted) return;

    if (widget.editExpenseId != null) {
      _isEditing = true;
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      _existingExpense = expenseProvider.expenses.firstWhere(
        (e) => e.id == widget.editExpenseId,
        orElse: () => throw Exception('Expense not found'),
      );

      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      _selectedCategory = categoryProvider.getCategoryById(_existingExpense!.categoryId);

      setState(() {
        _amountController.text = _existingExpense!.amount.toString();
        _merchantController.text = _existingExpense!.merchant ?? '';
        _notesController.text = _existingExpense!.description ?? '';
        _transactionDate = _existingExpense!.date;
        _transactionTime = TimeOfDay.fromDateTime(_existingExpense!.dateTime);
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  bool get _isOthersSelected =>
      _selectedCategory?.name.toLowerCase() == 'others';

  Future<void> _selectDate() async {
    final date = await DatePickerSheet.show(
      context,
      initialDate: _transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      title: 'Select Date',
    );

    if (date != null) {
      setState(() => _transactionDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _transactionTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              surface: AppColors.darkSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() => _transactionTime = time);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      CustomSnackBar.showError(context, message: 'Please select a category');
      return;
    }

    // Validate custom category if "Others" is selected
    if (_isOthersSelected && _customCategoryController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, message: 'Please specify the expense type');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId == null) return;

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    final dateTime = DateTime(
      _transactionDate.year,
      _transactionDate.month,
      _transactionDate.day,
      _transactionTime.hour,
      _transactionTime.minute,
    );

    final timeString = '${_transactionTime.hour.toString().padLeft(2, '0')}:${_transactionTime.minute.toString().padLeft(2, '0')}';

    // Build description - include custom category if "Others" selected
    String? description;
    if (_isOthersSelected && _customCategoryController.text.trim().isNotEmpty) {
      description = _customCategoryController.text.trim();
      if (_notesController.text.isNotEmpty) {
        description += ' - ${_notesController.text}';
      }
    } else {
      description = _notesController.text.isNotEmpty ? _notesController.text : null;
    }

    // Use custom category as merchant if not provided
    String? merchant = _merchantController.text.isNotEmpty
        ? _merchantController.text
        : (_isOthersSelected ? _customCategoryController.text.trim() : null);

    final expense = Expense(
      id: _isEditing ? _existingExpense!.id : null,
      userId: userId,
      categoryId: _selectedCategory!.id!,
      amount: double.parse(_amountController.text),
      merchant: merchant,
      date: _transactionDate,
      time: timeString,
      description: description,
      source: _isEditing ? _existingExpense!.source : 'MANUAL',
    );

    bool success;
    if (_isEditing) {
      success = await expenseProvider.updateExpense(expense);
    } else {
      success = await expenseProvider.addExpense(expense);
    }

    if (!mounted) return;

    if (success) {
      CustomSnackBar.showSuccess(
        context,
        message: _isEditing ? 'Expense updated' : 'Expense added',
      );
      Navigator.pop(context);
    } else {
      CustomSnackBar.showError(
        context,
        message: expenseProvider.error ?? 'Failed to save expense',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.darkBg,
              Color(0xFF1A1F3A),
              AppColors.darkBg,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: _isEditing ? 'Edit Expense' : 'Add Expense',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAmountInput(),
                        const SizedBox(height: 24),
                        _buildCategorySelector(),
                        const SizedBox(height: 20),
                        _buildDateTimeSelector(),
                        const SizedBox(height: 20),
                        _buildMerchantInput(),
                        const SizedBox(height: 20),
                        _buildNotesInput(),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount',
          style: TextStyle(
            color: AppColors.textLightSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        AmountTextField(
          controller: _amountController,
          validator: validateAmount,
          autofocus: true,
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            color: AppColors.textLightSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Consumer<CategoryProvider>(
          builder: (context, categoryProvider, child) {
            final categories = categoryProvider.visibleCategories;

            // Show loading or empty state
            if (categoryProvider.isLoading) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkCardLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            if (categories.isEmpty) {
              return GestureDetector(
                onTap: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final userId = authProvider.userId;
                  if (userId != null) {
                    await categoryProvider.loadCategories(userId);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.refresh, color: AppColors.accent),
                        SizedBox(height: 8),
                        Text(
                          'Tap to load categories',
                          style: TextStyle(color: AppColors.textLightSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: [
                // Dropdown for category selection
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedCategory != null
                          ? Color(_selectedCategory!.color)
                          : AppColors.glassBorder,
                      width: _selectedCategory != null ? 2 : 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Category>(
                      value: _selectedCategory,
                      isExpanded: true,
                      hint: const Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            color: AppColors.textLightSecondary,
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Select Category',
                            style: TextStyle(
                              color: AppColors.textLightSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      dropdownColor: AppColors.darkCard,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textLightSecondary,
                      ),
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 16,
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<Category>(
                          value: category,
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(category.color).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getCategoryIcon(category.icon),
                                  color: Color(category.color),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                category.name,
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (category) {
                        setState(() => _selectedCategory = category);
                      },
                      selectedItemBuilder: (context) {
                        return categories.map((category) {
                          return Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(category.color).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getCategoryIcon(category.icon),
                                  color: Color(category.color),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                category.name,
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
                // Show custom input when "Others" is selected
                if (_isOthersSelected) ...[
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _customCategoryController,
                    label: 'Specify Category',
                    hint: 'Enter expense type (e.g., Repair, Subscription)',
                    prefixIcon: Icons.edit,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateTimeSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCardLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(
                          color: AppColors.textLightSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        formatDate(_transactionDate),
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _selectTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCardLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time',
                        style: TextStyle(
                          color: AppColors.textLightSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _transactionTime.format(context),
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMerchantInput() {
    return CustomTextField(
      controller: _merchantController,
      label: 'Merchant (Optional)',
      hint: 'Where did you spend?',
      prefixIcon: Icons.store,
    );
  }

  Widget _buildNotesInput() {
    return CustomTextField(
      controller: _notesController,
      label: 'Notes (Optional)',
      hint: 'Add a note',
      prefixIcon: Icons.notes,
      maxLines: 3,
    );
  }

  Widget _buildSaveButton() {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        return SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: _isEditing ? 'Update Expense' : 'Add Expense',
            onPressed: expenseProvider.isLoading ? null : _saveExpense,
            isLoading: expenseProvider.isLoading,
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'shopping_cart': Icons.shopping_cart,
      'directions_car': Icons.directions_car,
      'local_gas_station': Icons.local_gas_station,
      'movie': Icons.movie,
      'medical_services': Icons.medical_services,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'receipt': Icons.receipt,
      'home': Icons.home,
      'phone_android': Icons.phone_android,
      'flight': Icons.flight,
      'fitness_center': Icons.fitness_center,
      'pets': Icons.pets,
      'card_giftcard': Icons.card_giftcard,
      'savings': Icons.savings,
      'more_horiz': Icons.more_horiz,
      'category': Icons.category,
      'local_grocery_store': Icons.local_grocery_store,
      'spa': Icons.spa,
      'trending_up': Icons.trending_up,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}
