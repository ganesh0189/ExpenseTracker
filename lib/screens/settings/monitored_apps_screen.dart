import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/themes.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/common.dart';

class MonitoredAppsScreen extends StatelessWidget {
  const MonitoredAppsScreen({super.key});

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
              const CustomAppBar(title: 'Monitored Apps'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPermissionCard(context),
                      const SizedBox(height: 20),
                      const Text(
                        'Payment Apps',
                        style: TextStyle(
                          color: AppColors.textLightSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAppList(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isEnabled = settingsProvider.notificationListenerEnabled;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isEnabled
                ? AppColors.incomeGradient
                : AppColors.expenseGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isEnabled ? Icons.check_circle : Icons.warning,
                    color: AppColors.textLight,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEnabled
                          ? 'Notification Access Enabled'
                          : 'Notification Access Required',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isEnabled
                    ? 'Money Tracker can read payment notifications from the selected apps below.'
                    : 'Grant notification access to automatically detect payments from your payment apps.',
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
              if (!isEnabled) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => settingsProvider.openNotificationSettings(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.expense,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Grant Access',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppList(BuildContext context) {
    final apps = [
      {
        'name': 'Google Pay',
        'package': 'com.google.android.apps.nbu.paisa.user',
        'icon': Icons.payments,
        'color': 0xFF4285F4,
      },
      {
        'name': 'PhonePe',
        'package': 'com.phonepe.app',
        'icon': Icons.account_balance_wallet,
        'color': 0xFF5F259F,
      },
      {
        'name': 'Paytm',
        'package': 'net.one97.paytm',
        'icon': Icons.credit_card,
        'color': 0xFF00BAF2,
      },
      {
        'name': 'Amazon Pay',
        'package': 'in.amazon.mShop.android.shopping',
        'icon': Icons.shopping_cart,
        'color': 0xFFFF9900,
      },
      {
        'name': 'Bank SMS',
        'package': 'com.android.messaging',
        'icon': Icons.sms,
        'color': 0xFF4CAF50,
      },
    ];

    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final enabledPackages = settingsProvider.enabledAppPackages;

        return Column(
          children: apps.map((app) {
            final isEnabled = enabledPackages.contains(app['package']);

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
                    color: Color(app['color'] as int).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    app['icon'] as IconData,
                    color: Color(app['color'] as int),
                    size: 24,
                  ),
                ),
                title: Text(
                  app['name'] as String,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  isEnabled ? 'Monitoring' : 'Not monitoring',
                  style: const TextStyle(
                    color: AppColors.textLightSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: Switch(
                  value: isEnabled,
                  onChanged: (value) {
                    // Toggle monitoring for this app
                    final monitoredApp = settingsProvider.monitoredApps
                        .firstWhere(
                          (a) => a.packageName == app['package'],
                          orElse: () => throw Exception('App not found'),
                        );
                    settingsProvider.toggleMonitoredApp(
                      monitoredApp.id!,
                      value,
                    );
                  },
                  activeColor: AppColors.accent,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
