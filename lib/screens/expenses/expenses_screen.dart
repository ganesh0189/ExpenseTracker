import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../models/expense.dart';
import '../../models/category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/common.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId == null) return;

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    await Future.wait([
      expenseProvider.loadExpenses(userId),
      categoryProvider.loadCategories(userId),
    ]);
  }

  Future<void> _changeMonth(int delta) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId == null) return;

    if (delta < 0) {
      await expenseProvider.previousMonth(userId);
    } else {
      await expenseProvider.nextMonth(userId);
    }

    setState(() {
      _selectedMonth = expenseProvider.selectedMonth;
      _selectedYear = expenseProvider.selectedYear;
    });
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
              _buildHeader(),
              _buildMonthSelector(),
              _buildMonthlyTotal(),
              _buildCategoryFilter(),
              Expanded(child: _buildExpenseList()),
            ],
          ),
        ),
      ),
      floatingActionButton: GradientIconButton(
        icon: Icons.add,
        size: 56,
        onPressed: () => Navigator.pushNamed(context, Routes.addExpense),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Expenses',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  // Show search
                },
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  // Show analytics
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: AppColors.textLight,
            ),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            formatMonthYear(_selectedMonth, _selectedYear),
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right,
              color: AppColors.textLight,
            ),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTotal() {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        final total = expenseProvider.monthlyTotal;

        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.expenseGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.expense.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Total Spent',
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatCurrency(total),
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final categories = categoryProvider.visibleCategories;

        return Container(
          height: 44,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCategoryChip(null, 'All');
              }
              final category = categories[index - 1];
              return _buildCategoryChip(category, category.name);
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(Category? category, String label) {
    final isSelected = category?.id == _selectedCategoryId ||
        (category == null && _selectedCategoryId == null);

    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = category?.id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.darkCardLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != null) ...[
              Icon(
                _getCategoryIcon(category.icon),
                size: 16,
                color: isSelected
                    ? AppColors.textLight
                    : Color(category.color),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.textLight
                    : AppColors.textLightSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseList() {
    return Consumer2<ExpenseProvider, CategoryProvider>(
      builder: (context, expenseProvider, categoryProvider, child) {
        var expenses = expenseProvider.expenses.toList();

        if (_selectedCategoryId != null) {
          expenses = expenses
              .where((e) => e.categoryId == _selectedCategoryId)
              .toList();
        }

        if (expenses.isEmpty) {
          return NoDataWidget(
            type: 'expenses',
            onAdd: () => Navigator.pushNamed(context, Routes.addExpense),
          );
        }

        // Group by date
        final groupedExpenses = <DateTime, List<Expense>>{};
        for (final expense in expenses) {
          final date = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );
          groupedExpenses.putIfAbsent(date, () => []).add(expense);
        }

        final sortedDates = groupedExpenses.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.accent,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dayExpenses = groupedExpenses[date]!;
              final dayTotal = dayExpenses.fold<double>(
                0,
                (sum, e) => sum + e.amount,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatRelativeDate(date),
                          style: const TextStyle(
                            color: AppColors.textLightSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          formatCurrency(dayTotal),
                          style: const TextStyle(
                            color: AppColors.expense,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...dayExpenses.map((expense) {
                    final category = categoryProvider.getCategoryById(expense.categoryId);
                    return _buildExpenseCard(expense, category);
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildExpenseCard(Expense expense, Category? category) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.expenseDetail,
        arguments: expense.id,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: category != null
                    ? Color(category.color).withOpacity(0.2)
                    : AppColors.darkCardLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                category != null
                    ? _getCategoryIcon(category.icon)
                    : Icons.receipt,
                color: category != null
                    ? Color(category.color)
                    : AppColors.textLightSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.merchant ?? category?.name ?? 'Expense',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        category?.name ?? 'Uncategorized',
                        style: const TextStyle(
                          color: AppColors.textLightSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (expense.source == 'AUTO') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Auto',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '-${formatCurrency(expense.amount)}',
              style: const TextStyle(
                color: AppColors.expense,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
    };
    return iconMap[iconName] ?? Icons.receipt;
  }
}
