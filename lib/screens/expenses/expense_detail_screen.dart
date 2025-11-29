import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../models/expense.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/common.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final int expenseId;

  const ExpenseDetailScreen({super.key, required this.expenseId});

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
        child: Consumer2<ExpenseProvider, CategoryProvider>(
          builder: (context, expenseProvider, categoryProvider, child) {
            final expense = expenseProvider.expenses.firstWhere(
              (e) => e.id == expenseId,
              orElse: () => throw Exception('Expense not found'),
            );
            final category = categoryProvider.getCategoryById(expense.categoryId);

            return SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context, expense),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildAmountCard(expense, category),
                          const SizedBox(height: 20),
                          _buildDetailsCard(expense, category),
                          const SizedBox(height: 20),
                          _buildActions(context, expense),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Expense expense) {
    return CustomAppBar(
      title: 'Expense Details',
      actions: [
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.darkCardLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.more_vert,
              color: AppColors.textLight,
              size: 20,
            ),
          ),
          color: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                Navigator.pushNamed(
                  context,
                  Routes.editExpense,
                  arguments: expense.id,
                );
                break;
              case 'delete':
                _confirmDelete(context, expense);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppColors.textLight, size: 20),
                  SizedBox(width: 12),
                  Text('Edit', style: TextStyle(color: AppColors.textLight)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.error, size: 20),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountCard(Expense expense, category) {
    return GradientCard(
      gradient: AppColors.expenseGradient,
      child: Column(
        children: [
          if (category != null) ...[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                _getCategoryIcon(category.icon),
                color: AppColors.textLight,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            expense.merchant ?? category?.name ?? 'Expense',
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(expense.amount),
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              expense.source == 'AUTO' ? 'Auto-detected' : 'Manual entry',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Expense expense, category) {
    return DarkCard(
      child: Column(
        children: [
          _buildDetailRow(
            'Category',
            category?.name ?? 'Uncategorized',
            Icons.category,
            iconColor: category != null ? Color(category.color) : null,
          ),
          const Divider(color: AppColors.glassBorder),
          _buildDetailRow(
            'Date',
            formatDate(expense.date),
            Icons.calendar_today,
          ),
          const Divider(color: AppColors.glassBorder),
          _buildDetailRow(
            'Time',
            formatTime(expense.dateTime),
            Icons.access_time,
          ),
          if (expense.description != null && expense.description!.isNotEmpty) ...[
            const Divider(color: AppColors.glassBorder),
            _buildDetailRow(
              'Notes',
              expense.description!,
              Icons.notes,
            ),
          ],
          const Divider(color: AppColors.glassBorder),
          _buildDetailRow(
            'Created',
            formatDateTime(expense.createdAt),
            Icons.history,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.accent).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textLightSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Expense expense) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'Edit Expense',
            icon: Icons.edit,
            onPressed: () => Navigator.pushNamed(
              context,
              Routes.editExpense,
              arguments: expense.id,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'Delete Expense',
            icon: Icons.delete_outline,
            isOutlined: true,
            gradient: AppColors.expenseGradient,
            onPressed: () => _confirmDelete(context, expense),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, Expense expense) async {
    final result = await ConfirmationDialog.show(
      context,
      title: 'Delete Expense',
      message: 'Are you sure you want to delete this expense? This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline,
    );

    if (result == true) {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await expenseProvider.deleteExpense(expense.id!, authProvider.userId!);
      if (context.mounted && success) {
        CustomSnackBar.showSuccess(context, message: 'Expense deleted');
        Navigator.pop(context);
      }
    }
  }
}
