import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../models/loan.dart';
import '../../models/partial_payment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/friend_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/common/common.dart';

class LoanDetailScreen extends StatefulWidget {
  final int loanId;

  const LoanDetailScreen({super.key, required this.loanId});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
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
        child: Consumer<LoanProvider>(
          builder: (context, loanProvider, child) {
            final loan = loanProvider.loans.firstWhere(
              (l) => l.id == widget.loanId,
              orElse: () => throw Exception('Loan not found'),
            );

            return SafeArea(
              child: Column(
                children: [
                  _buildAppBar(loan),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAmountCard(loan),
                          const SizedBox(height: 20),
                          _buildFriendCard(loan),
                          const SizedBox(height: 20),
                          _buildDetailsCard(loan),
                          const SizedBox(height: 20),
                          _buildPaymentHistory(loan),
                          const SizedBox(height: 20),
                          _buildActions(loan),
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

  Widget _buildAppBar(Loan loan) {
    return CustomAppBar(
      title: loan.type == 'LENT' ? 'Money Lent' : 'Money Borrowed',
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
                  Routes.editLoan,
                  arguments: loan.id,
                );
                break;
              case 'delete':
                _confirmDelete(loan);
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

  Widget _buildAmountCard(Loan loan) {
    final isLent = loan.type == 'LENT';

    return GradientCard(
      gradient: isLent ? AppColors.incomeGradient : AppColors.expenseGradient,
      child: Column(
        children: [
          Text(
            isLent ? 'Amount to Receive' : 'Amount to Pay',
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(loan.remainingAmount),
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (loan.paidAmount > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAmountDetail(
                  'Total',
                  formatCurrency(loan.amount),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildAmountDetail(
                  'Paid',
                  formatCurrency(loan.paidAmount),
                ),
              ],
            ),
          ],
          if (loan.isSettled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Settled',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textLight.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFriendCard(Loan loan) {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    final friend = friendProvider.getFriendById(loan.friendId);

    return DarkCard(
      onTap: friend != null
          ? () => Navigator.pushNamed(
                context,
                Routes.friendDetail,
                arguments: friend.id,
              )
          : null,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                friend?.name.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 22,
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
                  friend?.name ?? 'Unknown',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (friend?.phone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    friend!.phone!,
                    style: const TextStyle(
                      color: AppColors.textLightSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textLightSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Loan loan) {
    return DarkCard(
      child: Column(
        children: [
          _buildDetailRow('Loan Date', formatDate(loan.date), Icons.calendar_today),
          if (loan.dueDate != null) ...[
            const Divider(color: AppColors.glassBorder),
            _buildDetailRow(
              'Due Date',
              formatDate(loan.dueDate!),
              Icons.event,
              subtitle: formatDueStatus(loan.dueDate),
            ),
          ],
          if (loan.description != null && loan.description!.isNotEmpty) ...[
            const Divider(color: AppColors.glassBorder),
            _buildDetailRow('Description', loan.description!, Icons.notes),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {String? subtitle}) {
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
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.warning,
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

  Widget _buildPaymentHistory(Loan loan) {
    return Consumer<LoanProvider>(
      builder: (context, loanProvider, child) {
        return FutureBuilder<List<PartialPayment>>(
          future: loanProvider.getPartialPayments(loan.id!),
          builder: (context, snapshot) {
            final payments = snapshot.data ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment History',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!loan.isSettled)
                      TextButton(
                        onPressed: () => _showAddPaymentDialog(loan),
                        child: const Text(
                          'Add Payment',
                          style: TextStyle(color: AppColors.accent),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (payments.isEmpty)
                  const DarkCard(
                    child: Center(
                      child: Text(
                        'No payments recorded yet',
                        style: TextStyle(color: AppColors.textLightSecondary),
                      ),
                    ),
                  )
                else
                  ...payments.map((payment) => _buildPaymentItem(payment)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentItem(PartialPayment payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.success,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDate(payment.date),
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                ),
                if (payment.notes != null)
                  Text(
                    payment.notes!,
                    style: const TextStyle(
                      color: AppColors.textLightSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            formatCurrency(payment.amount),
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(Loan loan) {
    if (loan.isSettled) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'Mark as Settled',
            icon: Icons.check_circle_outline,
            onPressed: () => _confirmSettle(loan),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'Add Partial Payment',
            icon: Icons.payments_outlined,
            isOutlined: true,
            onPressed: () => _showAddPaymentDialog(loan),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddPaymentDialog(Loan loan) async {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
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
                'Add Payment',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Remaining: ${formatCurrency(loan.remainingAmount)}',
                style: const TextStyle(color: AppColors.textLightSecondary),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: amountController,
                label: 'Amount',
                hint: 'Enter payment amount',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
                validator: (value) {
                  final error = validateAmount(value);
                  if (error != null) return error;
                  final amount = double.tryParse(value!) ?? 0;
                  if (amount > loan.remainingAmount) {
                    return 'Amount cannot exceed remaining balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: notesController,
                label: 'Notes (Optional)',
                hint: 'Add a note',
                prefixIcon: Icons.notes,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      text: 'Cancel',
                      isOutlined: true,
                      height: 48,
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      text: 'Add',
                      height: 48,
                      onPressed: () async {
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) {
                          CustomSnackBar.showError(
                            context,
                            message: 'Please enter a valid amount',
                          );
                          return;
                        }

                        final loanProvider = Provider.of<LoanProvider>(
                          context,
                          listen: false,
                        );

                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        final payment = PartialPayment(
                          loanId: loan.id!,
                          amount: amount,
                          date: DateTime.now(),
                          notes: notesController.text.isNotEmpty
                              ? notesController.text
                              : null,
                        );

                        final success = await loanProvider.addPartialPayment(
                          payment,
                          authProvider.userId!,
                        );
                        if (context.mounted) {
                          Navigator.pop(context, success);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true && mounted) {
      CustomSnackBar.showSuccess(context, message: 'Payment added successfully');
    }
  }

  Future<void> _confirmSettle(Loan loan) async {
    final result = await ConfirmationDialog.show(
      context,
      title: 'Settle Loan',
      message: 'Are you sure you want to mark this loan as settled?',
      confirmText: 'Settle',
      icon: Icons.check_circle_outline,
    );

    if (result == true) {
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await loanProvider.settleLoan(loan.id!, authProvider.userId!);
      if (mounted && success) {
        CustomSnackBar.showSuccess(context, message: 'Loan marked as settled');
      }
    }
  }

  Future<void> _confirmDelete(Loan loan) async {
    final result = await ConfirmationDialog.show(
      context,
      title: 'Delete Loan',
      message: 'Are you sure you want to delete this loan? This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline,
    );

    if (result == true) {
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await loanProvider.deleteLoan(loan.id!, authProvider.userId!);
      if (mounted && success) {
        CustomSnackBar.showSuccess(context, message: 'Loan deleted');
        Navigator.pop(context);
      }
    }
  }
}
