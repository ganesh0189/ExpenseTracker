import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../models/friend.dart';
import '../../models/loan.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/loan_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/common.dart';

class FriendDetailScreen extends StatelessWidget {
  final int friendId;

  const FriendDetailScreen({super.key, required this.friendId});

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
        child: Consumer2<FriendProvider, LoanProvider>(
          builder: (context, friendProvider, loanProvider, child) {
            final friend = friendProvider.getFriendById(friendId);
            if (friend == null) {
              return const Center(
                child: Text(
                  'Friend not found',
                  style: TextStyle(color: AppColors.textLight),
                ),
              );
            }

            final balance = friendProvider.getNetBalanceForFriend(friendId);

            return SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context, friend),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildProfileCard(friend, balance),
                          const SizedBox(height: 20),
                          _buildContactCard(friend),
                          const SizedBox(height: 20),
                          _buildLoanHistoryAsync(context, loanProvider, friend),
                          const SizedBox(height: 20),
                          _buildActions(context, friend),
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

  Widget _buildAppBar(BuildContext context, Friend friend) {
    return CustomAppBar(
      title: 'Friend Details',
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
                  Routes.editFriend,
                  arguments: friend.id,
                );
                break;
              case 'delete':
                _confirmDelete(context, friend);
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

  Widget _buildProfileCard(Friend friend, double balance) {
    final isPositive = balance > 0;
    final isZero = balance == 0;

    return GradientCard(
      gradient: isZero
          ? AppColors.cardGradient
          : (isPositive ? AppColors.incomeGradient : AppColors.expenseGradient),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                friend.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            friend.name,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!isZero) ...[
            const SizedBox(height: 8),
            Text(
              isPositive ? 'To receive' : 'To pay',
              style: TextStyle(
                color: AppColors.textLight.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatCurrency(balance.abs()),
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'All settled up!',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactCard(Friend friend) {
    if (friend.phone == null && friend.email == null && friend.notes == null) {
      return const SizedBox.shrink();
    }

    return DarkCard(
      child: Column(
        children: [
          if (friend.phone != null)
            _buildContactRow(Icons.phone, 'Phone', friend.phone!),
          if (friend.email != null) ...[
            if (friend.phone != null)
              const Divider(color: AppColors.glassBorder),
            _buildContactRow(Icons.email, 'Email', friend.email!),
          ],
          if (friend.notes != null) ...[
            if (friend.phone != null || friend.email != null)
              const Divider(color: AppColors.glassBorder),
            _buildContactRow(Icons.notes, 'Notes', friend.notes!),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
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

  Widget _buildLoanHistoryAsync(BuildContext context, LoanProvider loanProvider, Friend friend) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    return FutureBuilder<List<Loan>>(
      future: userId != null
          ? loanProvider.getLoansByFriend(userId, friend.id!)
          : Future.value([]),
      builder: (context, snapshot) {
        final loans = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Loan History',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    Routes.addLoan,
                    arguments: friend.id,
                  ),
                  child: const Text(
                    'Add Loan',
                    style: TextStyle(color: AppColors.accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (loans.isEmpty)
              const DarkCard(
                child: Center(
                  child: Text(
                    'No loan history with this friend',
                    style: TextStyle(color: AppColors.textLightSecondary),
                  ),
                ),
              )
            else
              ...loans.map((loan) => _buildLoanItem(context, loan)),
          ],
        );
      },
    );
  }

  Widget _buildLoanItem(BuildContext context, Loan loan) {
    final isLent = loan.type == 'LENT';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.loanDetail,
        arguments: loan.id,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: loan.isSettled
                ? AppColors.success.withOpacity(0.3)
                : (isLent
                    ? AppColors.lent.withOpacity(0.3)
                    : AppColors.borrowed.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isLent ? Icons.arrow_upward : Icons.arrow_downward,
              color: isLent ? AppColors.lent : AppColors.borrowed,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLent ? 'Lent' : 'Borrowed',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    formatDate(loan.date),
                    style: const TextStyle(
                      color: AppColors.textLightSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(loan.remainingAmount),
                  style: TextStyle(
                    color: isLent ? AppColors.income : AppColors.expense,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (loan.isSettled)
                  const Text(
                    'Settled',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, Friend friend) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'Add New Loan',
            icon: Icons.add,
            onPressed: () => Navigator.pushNamed(
              context,
              Routes.addLoan,
              arguments: friend.id,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, Friend friend) async {
    final result = await ConfirmationDialog.show(
      context,
      title: 'Delete Friend',
      message:
          'Are you sure you want to delete ${friend.name}? This will also delete all associated loans.',
      confirmText: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline,
    );

    if (result == true) {
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await friendProvider.deleteFriend(friend.id!, authProvider.userId!);
      if (context.mounted && success) {
        CustomSnackBar.showSuccess(context, message: 'Friend deleted');
        Navigator.pop(context);
      }
    }
  }
}
