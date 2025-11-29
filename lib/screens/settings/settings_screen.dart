import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/common.dart';
import '../../utils/formatters.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildProfileSection(context),
                const SizedBox(height: 20),
                _buildSection(context, 'Preferences', [
                  _buildThemeTile(context),
                  _buildBudgetTile(context),
                  _buildTile(
                    icon: Icons.category,
                    title: 'Categories',
                    subtitle: 'Manage expense categories',
                    onTap: () => Navigator.pushNamed(context, Routes.categories),
                  ),
                ]),
                _buildSection(context, 'Auto-Detection', [
                  _buildAutoDetectTile(context),
                  _buildTile(
                    icon: Icons.apps,
                    title: 'Monitored Apps',
                    subtitle: 'Select payment apps to track',
                    onTap: () => Navigator.pushNamed(context, Routes.monitoredApps),
                  ),
                  _buildTile(
                    icon: Icons.rule,
                    title: 'Merchant Rules',
                    subtitle: 'Auto-categorize by merchant',
                    onTap: () => Navigator.pushNamed(context, Routes.merchantRules),
                  ),
                ]),
                _buildSection(context, 'Data', [
                  _buildTile(
                    icon: Icons.download,
                    title: 'Export Data',
                    subtitle: 'Download your data as CSV/JSON',
                    onTap: () => Navigator.pushNamed(context, Routes.exportData),
                  ),
                  _buildClearDataTile(context),
                ]),
                _buildSection(context, 'Security', [
                  _buildTile(
                    icon: Icons.lock,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  _buildTile(
                    icon: Icons.pin,
                    title: 'Change PIN',
                    subtitle: 'Update your quick login PIN',
                    onTap: () => _showChangePinDialog(context),
                  ),
                ]),
                _buildSection(context, 'About', [
                  _buildTile(
                    icon: Icons.info,
                    title: 'App Version',
                    subtitle: '1.0.0',
                    showArrow: false,
                  ),
                  _buildTile(
                    icon: Icons.person,
                    title: 'Developed by',
                    subtitle: 'Ganesh Bollem',
                    showArrow: false,
                  ),
                ]),
                _buildLogoutButton(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Text(
        'Settings',
        style: TextStyle(
          color: AppColors.textLight,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DarkCard(
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      user.fullName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          color: AppColors.textLightSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> tiles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textLightSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: tiles
                  .map((tile) => Column(
                        children: [
                          tile,
                          if (tiles.indexOf(tile) < tiles.length - 1)
                            const Divider(
                              color: AppColors.glassBorder,
                              height: 1,
                              indent: 56,
                            ),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    bool showArrow = true,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.accent, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textLight,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textLightSecondary,
          fontSize: 12,
        ),
      ),
      trailing: trailing ??
          (showArrow
              ? const Icon(
                  Icons.chevron_right,
                  color: AppColors.textLightSecondary,
                )
              : null),
      onTap: onTap,
    );
  }

  Widget _buildThemeTile(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return _buildTile(
          icon: Icons.dark_mode,
          title: 'Theme',
          subtitle: _getThemeName(settingsProvider.themeMode),
          trailing: DropdownButton<ThemeMode>(
            value: settingsProvider.themeMode,
            dropdownColor: AppColors.darkSurface,
            underline: const SizedBox(),
            icon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.textLightSecondary,
            ),
            items: ThemeMode.values.map((mode) {
              return DropdownMenuItem(
                value: mode,
                child: Text(
                  _getThemeName(mode),
                  style: const TextStyle(color: AppColors.textLight),
                ),
              );
            }).toList(),
            onChanged: (mode) {
              if (mode != null) {
                settingsProvider.setThemeMode(mode);
              }
            },
          ),
        );
      },
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      default:
        return 'System';
    }
  }

  Widget _buildBudgetTile(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return _buildTile(
          icon: Icons.account_balance_wallet,
          title: 'Monthly Budget',
          subtitle: formatCurrency(settingsProvider.monthlyBudget),
          onTap: () => _showBudgetDialog(context, settingsProvider.monthlyBudget),
        );
      },
    );
  }

  Future<void> _showBudgetDialog(BuildContext context, double currentBudget) async {
    final controller = TextEditingController(text: currentBudget.toStringAsFixed(0));

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Set Monthly Budget',
          style: TextStyle(color: AppColors.textLight),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: AppColors.textLight, fontSize: 24),
          decoration: InputDecoration(
            prefixText: '₹ ',
            prefixStyle: const TextStyle(color: AppColors.textLight, fontSize: 24),
            filled: true,
            fillColor: AppColors.darkCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: '50000',
            hintStyle: TextStyle(color: AppColors.textLightSecondary.withOpacity(0.5)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textLightSecondary)),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Save', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final userId = authProvider.userId;

      if (userId != null) {
        await settingsProvider.setMonthlyBudget(userId, result);
        if (context.mounted) {
          CustomSnackBar.showSuccess(context, message: 'Budget updated to ${formatCurrency(result)}');
        }
      }
    }
  }

  Widget _buildAutoDetectTile(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return _buildTile(
          icon: Icons.auto_awesome,
          title: 'Auto-Detect Payments',
          subtitle: settingsProvider.notificationListenerEnabled
              ? 'Enabled'
              : 'Tap to enable',
          trailing: Switch(
            value: settingsProvider.autoDetectEnabled,
            onChanged: (value) async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final userId = authProvider.userId;
              if (userId != null) {
                await settingsProvider.setAutoDetectEnabled(userId, value);
                if (value && !settingsProvider.notificationListenerEnabled) {
                  settingsProvider.openNotificationSettings();
                }
              }
            },
            activeColor: AppColors.accent,
          ),
        );
      },
    );
  }

  Widget _buildClearDataTile(BuildContext context) {
    return _buildTile(
      icon: Icons.delete_sweep,
      title: 'Clear Data',
      subtitle: 'Delete all your data',
      onTap: () => _showClearDataDialog(context),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: GradientButton(
          text: 'Logout',
          icon: Icons.logout,
          isOutlined: true,
          gradient: AppColors.expenseGradient,
          onPressed: () => _confirmLogout(context),
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    // TODO: Implement change password
    CustomSnackBar.showInfo(context, message: 'Coming soon!');
  }

  Future<void> _showChangePinDialog(BuildContext context) async {
    // TODO: Implement change PIN
    CustomSnackBar.showInfo(context, message: 'Coming soon!');
  }

  Future<void> _showClearDataDialog(BuildContext context) async {
    final result = await ConfirmationDialog.show(
      context,
      title: 'Clear All Data',
      message:
          'This will permanently delete all your expenses, loans, and friends. This action cannot be undone.',
      confirmText: 'Clear All',
      isDestructive: true,
      icon: Icons.delete_forever,
    );

    if (result == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      final userId = authProvider.userId;

      if (userId != null) {
        final success = await settingsProvider.clearAllData(userId);
        if (context.mounted) {
          if (success) {
            CustomSnackBar.showSuccess(context, message: 'All data cleared');
          } else {
            CustomSnackBar.showError(context, message: 'Failed to clear data');
          }
        }
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final result = await ConfirmationDialog.show(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      icon: Icons.logout,
    );

    if (result == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.login,
          (route) => false,
        );
      }
    }
  }
}
