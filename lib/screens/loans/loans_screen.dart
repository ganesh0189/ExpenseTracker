import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../models/loan.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/friend_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/common.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'all'; // all, pending, settled

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId == null) return;

    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);

    await Future.wait([
      loanProvider.loadLoans(userId),
      friendProvider.loadFriends(userId),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              _buildTabBar(),
              _buildFilterChips(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLoanList('LENT'),
                    _buildLoanList('BORROWED'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Loans',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
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
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.darkCardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: AppColors.textLight,
        unselectedLabelColor: AppColors.textLightSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Money Lent'),
          Tab(text: 'Money Borrowed'),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Pending', 'pending'),
          const SizedBox(width: 8),
          _buildFilterChip('Settled', 'settled'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.darkCardLight,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: AppColors.glassBorder, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textLight : AppColors.textLightSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLoanList(String type) {
    return Consumer<LoanProvider>(
      builder: (context, loanProvider, child) {
        List<Loan> loans;
        if (type == 'LENT') {
          loans = loanProvider.lentLoans;
        } else {
          loans = loanProvider.borrowedLoans;
        }

        // Apply filter
        if (_filter == 'pending') {
          loans = loans.where((l) => !l.isSettled).toList();
        } else if (_filter == 'settled') {
          loans = loans.where((l) => l.isSettled).toList();
        }

        if (loans.isEmpty) {
          return NoDataWidget(
            type: 'loans',
            onAdd: () => Navigator.pushNamed(context, Routes.addLoan),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.accent,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: loans.length,
            itemBuilder: (context, index) {
              return _buildLoanCard(loans[index], type);
            },
          ),
        );
      },
    );
  }

  Widget _buildLoanCard(Loan loan, String type) {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    final friend = friendProvider.getFriendById(loan.friendId);
    final isLent = type == 'LENT';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.loanDetail,
          arguments: loan.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: loan.isSettled
                ? AppColors.success.withOpacity(0.3)
                : (isLent
                    ? AppColors.lent.withOpacity(0.3)
                    : AppColors.borrowed.withOpacity(0.3)),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isLent
                        ? AppColors.incomeGradient
                        : AppColors.expenseGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      friend?.name.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Friend name and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend?.name ?? 'Unknown',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRelativeDate(loan.date),
                        style: const TextStyle(
                          color: AppColors.textLightSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(loan.remainingAmount),
                      style: TextStyle(
                        color: isLent ? AppColors.income : AppColors.expense,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (loan.isSettled)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Settled',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (loan.description != null && loan.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                loan.description!,
                style: const TextStyle(
                  color: AppColors.textLightSecondary,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (loan.dueDate != null && !loan.isSettled) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getDueDateColor(loan.dueDate!).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: _getDueDateColor(loan.dueDate!),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatDueStatus(loan.dueDate),
                      style: TextStyle(
                        color: _getDueDateColor(loan.dueDate!),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final diff = dueDate.difference(now).inDays;
    if (diff < 0) return AppColors.error;
    if (diff <= 3) return AppColors.warning;
    return AppColors.textLightSecondary;
  }

  Widget _buildFAB() {
    return GradientIconButton(
      icon: Icons.add,
      size: 56,
      onPressed: () => Navigator.pushNamed(context, Routes.addLoan),
    );
  }
}
