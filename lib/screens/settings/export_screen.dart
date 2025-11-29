import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/themes.dart';
import '../../providers/auth_provider.dart';
import '../../services/export_service.dart';
import '../../widgets/common/common.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ExportService _exportService = ExportService();
  bool _isExporting = false;

  Future<void> _exportExpenses() async {
    setState(() => _isExporting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    if (userId != null) {
      final result = await _exportService.exportExpensesToCsv(userId);
      if (mounted) {
        if (result.success) {
          CustomSnackBar.showSuccess(
            context,
            message: 'Expenses exported to Downloads folder',
          );
        } else {
          CustomSnackBar.showError(
            context,
            message: result.error ?? 'Failed to export expenses',
          );
        }
      }
    }

    setState(() => _isExporting = false);
  }

  Future<void> _exportLoans() async {
    setState(() => _isExporting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    if (userId != null) {
      final result = await _exportService.exportLoansToCsv(userId);
      if (mounted) {
        if (result.success) {
          CustomSnackBar.showSuccess(
            context,
            message: 'Loans exported to Downloads folder',
          );
        } else {
          CustomSnackBar.showError(
            context,
            message: result.error ?? 'Failed to export loans',
          );
        }
      }
    }

    setState(() => _isExporting = false);
  }

  Future<void> _exportAllData() async {
    setState(() => _isExporting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    if (userId != null) {
      final result = await _exportService.exportAllDataToJson(userId);
      if (mounted) {
        if (result.success) {
          CustomSnackBar.showSuccess(
            context,
            message: 'All data exported to Downloads folder',
          );
        } else {
          CustomSnackBar.showError(
            context,
            message: result.error ?? 'Failed to export data',
          );
        }
      }
    }

    setState(() => _isExporting = false);
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
              const CustomAppBar(title: 'Export Data'),
              Expanded(
                child: LoadingOverlay(
                  isLoading: _isExporting,
                  message: 'Exporting...',
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 24),
                        const Text(
                          'Export Options',
                          style: TextStyle(
                            color: AppColors.textLightSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildExportOption(
                          icon: Icons.receipt_long,
                          title: 'Export Expenses',
                          subtitle: 'Download all expenses as CSV',
                          color: AppColors.expense,
                          onTap: _exportExpenses,
                        ),
                        const SizedBox(height: 12),
                        _buildExportOption(
                          icon: Icons.account_balance_wallet,
                          title: 'Export Loans',
                          subtitle: 'Download all loans as CSV',
                          color: AppColors.lent,
                          onTap: _exportLoans,
                        ),
                        const SizedBox(height: 12),
                        _buildExportOption(
                          icon: Icons.storage,
                          title: 'Export All Data',
                          subtitle: 'Download everything as JSON',
                          color: AppColors.accent,
                          onTap: _exportAllData,
                        ),
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.textLight,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Data, Your Control',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Export your data anytime. Files are saved to your Downloads folder.',
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isExporting ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textLightSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download,
              color: color,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
