import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/themes.dart';
import '../../models/merchant_rule.dart';
import '../../models/category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/category_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/common/common.dart';

class MerchantRulesScreen extends StatefulWidget {
  const MerchantRulesScreen({super.key});

  @override
  State<MerchantRulesScreen> createState() => _MerchantRulesScreenState();
}

class _MerchantRulesScreenState extends State<MerchantRulesScreen> {
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
              const CustomAppBar(title: 'Merchant Rules'),
              Expanded(
                child: Consumer<SettingsProvider>(
                  builder: (context, settingsProvider, child) {
                    final rules = settingsProvider.merchantRules;

                    if (rules.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.rule,
                                size: 50,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No Rules Yet',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add rules to auto-categorize expenses\nbased on merchant name',
                              style: TextStyle(
                                color: AppColors.textLightSecondary,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            GradientButton(
                              text: 'Add Rule',
                              icon: Icons.add,
                              onPressed: () => _showAddRuleDialog(),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: rules.length,
                      itemBuilder: (context, index) {
                        return _buildRuleTile(rules[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.merchantRules.isEmpty) {
            return const SizedBox.shrink();
          }
          return GradientIconButton(
            icon: Icons.add,
            size: 56,
            onPressed: () => _showAddRuleDialog(),
          );
        },
      ),
    );
  }

  Widget _buildRuleTile(MerchantRule rule) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final category = categoryProvider.getCategoryById(rule.categoryId);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: category != null
                    ? Color(category.color).withOpacity(0.2)
                    : AppColors.darkCardLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category != null
                    ? _getCategoryIcon(category.icon)
                    : Icons.category,
                color: category != null
                    ? Color(category.color)
                    : AppColors.textLightSecondary,
                size: 24,
              ),
            ),
            title: Text(
              rule.pattern,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '→ ${category?.name ?? 'Unknown Category'}',
              style: const TextStyle(
                color: AppColors.textLightSecondary,
                fontSize: 12,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 20,
              ),
              onPressed: () => _confirmDeleteRule(rule),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddRuleDialog() async {
    final patternController = TextEditingController();
    Category? selectedCategory;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Merchant Rule',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'When a merchant name contains the pattern, it will be automatically categorized.',
                    style: TextStyle(
                      color: AppColors.textLightSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: patternController,
                    label: 'Pattern',
                    hint: 'e.g., Swiggy, Zomato, Amazon',
                    validator: validatePattern,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Category',
                    style: TextStyle(
                      color: AppColors.textLightSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<CategoryProvider>(
                    builder: (context, categoryProvider, child) {
                      final categories = categoryProvider.visibleCategories;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.darkCardLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButton<Category>(
                          value: selectedCategory,
                          hint: const Text(
                            'Select category',
                            style: TextStyle(color: AppColors.textLightSecondary),
                          ),
                          isExpanded: true,
                          dropdownColor: AppColors.darkSurface,
                          underline: const SizedBox(),
                          items: categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(
                                    _getCategoryIcon(category.icon),
                                    color: Color(category.color),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    category.name,
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() => selectedCategory = value);
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GradientButton(
                          text: 'Cancel',
                          isOutlined: true,
                          height: 48,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GradientButton(
                          text: 'Add',
                          height: 48,
                          onPressed: () async {
                            if (patternController.text.trim().isEmpty) {
                              CustomSnackBar.showError(
                                context,
                                message: 'Please enter a pattern',
                              );
                              return;
                            }
                            if (selectedCategory == null) {
                              CustomSnackBar.showError(
                                context,
                                message: 'Please select a category',
                              );
                              return;
                            }

                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            final settingsProvider =
                                Provider.of<SettingsProvider>(
                              context,
                              listen: false,
                            );

                            final rule = MerchantRule(
                              userId: authProvider.userId!,
                              pattern: patternController.text.trim(),
                              merchantName: patternController.text.trim(),
                              categoryId: selectedCategory!.id!,
                            );

                            final success =
                                await settingsProvider.addMerchantRule(rule);
                            if (context.mounted) {
                              Navigator.pop(context);
                              if (success) {
                                CustomSnackBar.showSuccess(
                                  context,
                                  message: 'Rule added',
                                );
                              } else {
                                CustomSnackBar.showError(
                                  context,
                                  message: settingsProvider.error ??
                                      'Failed to add rule',
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteRule(MerchantRule rule) async {
    final result = await ConfirmationDialog.show(
      context,
      title: 'Delete Rule',
      message: 'Are you sure you want to delete this rule?',
      confirmText: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline,
    );

    if (result == true) {
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      final success = await settingsProvider.deleteMerchantRule(rule.id!);
      if (mounted && success) {
        CustomSnackBar.showSuccess(context, message: 'Rule deleted');
      }
    }
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
