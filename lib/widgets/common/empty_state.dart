import 'package:flutter/material.dart';
import '../../config/themes.dart';
import 'gradient_button.dart';

/// Modern empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.buttonText,
    this.onButtonPressed,
    this.iconSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with gradient background
            Container(
              width: iconSize + 40,
              height: iconSize + 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryStart.withOpacity(0.2),
                    AppColors.primaryEnd.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: AppColors.textLightSecondary,
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            // Message
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: const TextStyle(
                  color: AppColors.textLightSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            // Action button
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              GradientButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                icon: Icons.add,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state for specific scenarios
class NoDataWidget extends StatelessWidget {
  final String type; // 'loans', 'expenses', 'friends', etc.
  final VoidCallback? onAdd;

  const NoDataWidget({
    super.key,
    required this.type,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(type);
    return EmptyState(
      icon: config['icon'] as IconData,
      title: config['title'] as String,
      message: config['message'] as String,
      buttonText: config['buttonText'] as String?,
      onButtonPressed: onAdd,
    );
  }

  Map<String, dynamic> _getConfig(String type) {
    switch (type) {
      case 'loans':
        return {
          'icon': Icons.account_balance_wallet_outlined,
          'title': 'No Loans Yet',
          'message': 'Start tracking money you\'ve lent or borrowed',
          'buttonText': 'Add Loan',
        };
      case 'expenses':
        return {
          'icon': Icons.receipt_long_outlined,
          'title': 'No Expenses Yet',
          'message': 'Add your first expense to start tracking',
          'buttonText': 'Add Expense',
        };
      case 'friends':
        return {
          'icon': Icons.people_outline,
          'title': 'No Friends Yet',
          'message': 'Add friends to track loans with them',
          'buttonText': 'Add Friend',
        };
      case 'categories':
        return {
          'icon': Icons.category_outlined,
          'title': 'No Categories',
          'message': 'Create custom categories for your expenses',
          'buttonText': 'Add Category',
        };
      case 'search':
        return {
          'icon': Icons.search_off,
          'title': 'No Results Found',
          'message': 'Try searching with different keywords',
          'buttonText': null,
        };
      case 'notifications':
        return {
          'icon': Icons.notifications_off_outlined,
          'title': 'No Notifications',
          'message': 'You\'re all caught up!',
          'buttonText': null,
        };
      default:
        return {
          'icon': Icons.inbox_outlined,
          'title': 'Nothing Here',
          'message': 'This section is empty',
          'buttonText': null,
        };
    }
  }
}

/// Error state widget
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 60,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textLightSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              GradientButton(
                text: 'Try Again',
                onPressed: onRetry,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
