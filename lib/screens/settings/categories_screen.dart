import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/themes.dart';
import '../../models/category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/common/common.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
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
              const CustomAppBar(title: 'Categories'),
              Expanded(
                child: Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, child) {
                    final categories = categoryProvider.categories;

                    if (categories.isEmpty) {
                      return const NoDataWidget(type: 'categories');
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryTile(categories[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: GradientIconButton(
        icon: Icons.add,
        size: 56,
        onPressed: () => _showAddCategoryDialog(),
      ),
    );
  }

  Widget _buildCategoryTile(Category category) {
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
            color: Color(category.color).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getCategoryIcon(category.icon),
            color: Color(category.color),
            size: 24,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          category.isDefault ? 'Default' : 'Custom',
          style: const TextStyle(
            color: AppColors.textLightSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!category.isDefault)
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppColors.textLightSecondary,
                  size: 20,
                ),
                onPressed: () => _showEditCategoryDialog(category),
              ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: !category.isHidden,
                onChanged: (value) async {
                  final categoryProvider =
                      Provider.of<CategoryProvider>(context, listen: false);
                  if (value) {
                    await categoryProvider.showCategory(category.id!);
                  } else {
                    await categoryProvider.hideCategory(category.id!);
                  }
                },
                activeColor: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    int selectedColor = AppColors.accent.value;
    String selectedIcon = 'receipt';

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
                    'Add Category',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: nameController,
                    label: 'Category Name',
                    hint: 'Enter category name',
                    validator: validateCategoryName,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Color',
                    style: TextStyle(
                      color: AppColors.textLightSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categoryColors.map((color) {
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: selectedColor == color
                                ? Border.all(
                                    color: AppColors.textLight, width: 2)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Icon',
                    style: TextStyle(
                      color: AppColors.textLightSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categoryIcons.entries.map((entry) {
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedIcon = entry.key),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: selectedIcon == entry.key
                                ? Color(selectedColor).withOpacity(0.3)
                                : AppColors.darkCardLight,
                            borderRadius: BorderRadius.circular(10),
                            border: selectedIcon == entry.key
                                ? Border.all(
                                    color: Color(selectedColor), width: 2)
                                : null,
                          ),
                          child: Icon(
                            entry.value,
                            color: Color(selectedColor),
                            size: 22,
                          ),
                        ),
                      );
                    }).toList(),
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
                            if (nameController.text.trim().isEmpty) {
                              CustomSnackBar.showError(
                                context,
                                message: 'Please enter a category name',
                              );
                              return;
                            }

                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            final categoryProvider =
                                Provider.of<CategoryProvider>(
                              context,
                              listen: false,
                            );

                            final category = Category(
                              userId: authProvider.userId!,
                              name: nameController.text.trim(),
                              icon: selectedIcon,
                              color: selectedColor,
                              isDefault: false,
                            );

                            final success =
                                await categoryProvider.addCategory(category);
                            if (context.mounted) {
                              Navigator.pop(context);
                              if (success) {
                                CustomSnackBar.showSuccess(
                                  context,
                                  message: 'Category added',
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

  Future<void> _showEditCategoryDialog(Category category) async {
    final nameController = TextEditingController(text: category.name);
    int selectedColor = category.color;
    String selectedIcon = category.icon;

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
                    'Edit Category',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: nameController,
                    label: 'Category Name',
                    hint: 'Enter category name',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Color',
                    style: TextStyle(
                      color: AppColors.textLightSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categoryColors.map((color) {
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: selectedColor == color
                                ? Border.all(
                                    color: AppColors.textLight, width: 2)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
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
                          text: 'Save',
                          height: 48,
                          onPressed: () async {
                            final categoryProvider =
                                Provider.of<CategoryProvider>(
                              context,
                              listen: false,
                            );

                            final updatedCategory = category.copyWith(
                              name: nameController.text.trim(),
                              icon: selectedIcon,
                              color: selectedColor,
                            );

                            final success = await categoryProvider
                                .updateCategory(updatedCategory);
                            if (context.mounted) {
                              Navigator.pop(context);
                              if (success) {
                                CustomSnackBar.showSuccess(
                                  context,
                                  message: 'Category updated',
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

  IconData _getCategoryIcon(String iconName) {
    return _categoryIcons[iconName] ?? Icons.receipt;
  }

  static const List<int> _categoryColors = [
    0xFFFF4757, // Red
    0xFFFF6B81, // Pink
    0xFFFF006E, // Magenta
    0xFF764BA2, // Purple
    0xFF667EEA, // Indigo
    0xFF00D9FF, // Cyan
    0xFF00F5A0, // Green
    0xFFFFBE0B, // Yellow
    0xFFFF8C00, // Orange
  ];

  static const Map<String, IconData> _categoryIcons = {
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
}
