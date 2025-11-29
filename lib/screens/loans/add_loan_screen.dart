import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../models/loan.dart';
import '../../models/friend.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/friend_provider.dart';
import '../../utils/validators.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/common.dart';

class AddLoanScreen extends StatefulWidget {
  final int? preselectedFriendId;
  final int? editLoanId;

  const AddLoanScreen({
    super.key,
    this.preselectedFriendId,
    this.editLoanId,
  });

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _loanType = 'LENT';
  Friend? _selectedFriend;
  DateTime _loanDate = DateTime.now();
  DateTime? _dueDate;
  bool _setReminder = false;
  bool _isEditing = false;
  Loan? _existingLoan;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (widget.editLoanId != null) {
      _isEditing = true;
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);
      _existingLoan = loanProvider.loans.firstWhere(
        (l) => l.id == widget.editLoanId,
        orElse: () => throw Exception('Loan not found'),
      );

      setState(() {
        _loanType = _existingLoan!.type;
        _amountController.text = _existingLoan!.amount.toString();
        _descriptionController.text = _existingLoan!.description ?? '';
        _loanDate = _existingLoan!.date;
        _dueDate = _existingLoan!.dueDate;
        _setReminder = _existingLoan!.reminderEnabled;
      });

      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      _selectedFriend = friendProvider.getFriendById(_existingLoan!.friendId);
    } else if (widget.preselectedFriendId != null) {
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      _selectedFriend = friendProvider.getFriendById(widget.preselectedFriendId!);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isDueDate) async {
    final date = await DatePickerSheet.show(
      context,
      initialDate: isDueDate ? _dueDate : _loanDate,
      firstDate: isDueDate ? DateTime.now() : DateTime(2000),
      lastDate: DateTime(2100),
      title: isDueDate ? 'Select Due Date' : 'Select Loan Date',
    );

    if (date != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = date;
        } else {
          _loanDate = date;
        }
      });
    }
  }

  Future<void> _selectFriend() async {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    final friends = friendProvider.friends;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FriendSelectorSheet(
        friends: friends,
        selectedFriend: _selectedFriend,
        onSelect: (friend) {
          setState(() => _selectedFriend = friend);
          Navigator.pop(context);
        },
        onAddNew: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, Routes.addFriend);
        },
      ),
    );
  }

  Future<void> _saveLoan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFriend == null) {
      CustomSnackBar.showError(context, message: 'Please select a friend');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId == null) return;

    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    final loan = Loan(
      id: _isEditing ? _existingLoan!.id : null,
      userId: userId,
      friendId: _selectedFriend!.id!,
      type: _loanType,
      amount: double.parse(_amountController.text),
      date: _loanDate,
      dueDate: _dueDate,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      reminderEnabled: _setReminder,
      isSettled: _isEditing ? _existingLoan!.isSettled : false,
    );

    bool success;
    if (_isEditing) {
      success = await loanProvider.updateLoan(loan);
    } else {
      success = await loanProvider.addLoan(loan);
    }

    if (!mounted) return;

    if (success) {
      CustomSnackBar.showSuccess(
        context,
        message: _isEditing ? 'Loan updated successfully' : 'Loan added successfully',
      );
      Navigator.pop(context);
    } else {
      CustomSnackBar.showError(
        context,
        message: loanProvider.error ?? 'Failed to save loan',
      );
    }
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
              CustomAppBar(
                title: _isEditing ? 'Edit Loan' : 'Add Loan',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLoanTypeSelector(),
                        const SizedBox(height: 24),
                        _buildAmountInput(),
                        const SizedBox(height: 24),
                        _buildFriendSelector(),
                        const SizedBox(height: 20),
                        _buildDateSelector(),
                        const SizedBox(height: 20),
                        _buildDueDateSelector(),
                        const SizedBox(height: 20),
                        _buildDescriptionInput(),
                        const SizedBox(height: 20),
                        _buildReminderToggle(),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
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

  Widget _buildLoanTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _loanType = 'LENT'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: _loanType == 'LENT'
                    ? AppColors.incomeGradient
                    : null,
                color: _loanType == 'LENT' ? null : AppColors.darkCardLight,
                borderRadius: BorderRadius.circular(16),
                border: _loanType == 'LENT'
                    ? null
                    : Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.arrow_upward,
                    color: _loanType == 'LENT'
                        ? AppColors.textLight
                        : AppColors.textLightSecondary,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'I Lent',
                    style: TextStyle(
                      color: _loanType == 'LENT'
                          ? AppColors.textLight
                          : AppColors.textLightSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Money given',
                    style: TextStyle(
                      color: _loanType == 'LENT'
                          ? AppColors.textLight.withOpacity(0.8)
                          : AppColors.textLightSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _loanType = 'BORROWED'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: _loanType == 'BORROWED'
                    ? AppColors.expenseGradient
                    : null,
                color: _loanType == 'BORROWED' ? null : AppColors.darkCardLight,
                borderRadius: BorderRadius.circular(16),
                border: _loanType == 'BORROWED'
                    ? null
                    : Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.arrow_downward,
                    color: _loanType == 'BORROWED'
                        ? AppColors.textLight
                        : AppColors.textLightSecondary,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'I Borrowed',
                    style: TextStyle(
                      color: _loanType == 'BORROWED'
                          ? AppColors.textLight
                          : AppColors.textLightSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Money taken',
                    style: TextStyle(
                      color: _loanType == 'BORROWED'
                          ? AppColors.textLight.withOpacity(0.8)
                          : AppColors.textLightSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount',
          style: TextStyle(
            color: AppColors.textLightSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        AmountTextField(
          controller: _amountController,
          validator: validateAmount,
          autofocus: true,
        ),
      ],
    );
  }

  Widget _buildFriendSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Friend',
          style: TextStyle(
            color: AppColors.textLightSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectFriend,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCardLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                if (_selectedFriend != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _selectedFriend!.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedFriend!.name,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.person_add_outlined,
                    color: AppColors.textLightSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select a friend',
                      style: TextStyle(
                        color: AppColors.textLightSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textLightSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () => _selectDate(false),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCardLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AppColors.accent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date',
                  style: TextStyle(
                    color: AppColors.textLightSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDate(_loanDate),
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateSelector() {
    return GestureDetector(
      onTap: () => _selectDate(true),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCardLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event,
              color: _dueDate != null ? AppColors.warning : AppColors.textLightSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Due Date (Optional)',
                    style: TextStyle(
                      color: AppColors.textLightSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dueDate != null ? formatDate(_dueDate!) : 'Not set',
                    style: TextStyle(
                      color: _dueDate != null
                          ? AppColors.textLight
                          : AppColors.textLightSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            if (_dueDate != null)
              IconButton(
                icon: const Icon(
                  Icons.clear,
                  color: AppColors.textLightSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _dueDate = null),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return CustomTextField(
      controller: _descriptionController,
      label: 'Description (Optional)',
      hint: 'What is this loan for?',
      maxLines: 3,
      prefixIcon: Icons.notes,
    );
  }

  Widget _buildReminderToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_outlined,
            color: AppColors.accent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set Reminder',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Get notified about this loan',
                  style: TextStyle(
                    color: AppColors.textLightSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _setReminder,
            onChanged: (value) => setState(() => _setReminder = value),
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Consumer<LoanProvider>(
      builder: (context, loanProvider, child) {
        return SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: _isEditing ? 'Update Loan' : 'Add Loan',
            onPressed: loanProvider.isLoading ? null : _saveLoan,
            isLoading: loanProvider.isLoading,
          ),
        );
      },
    );
  }
}

class _FriendSelectorSheet extends StatelessWidget {
  final List<Friend> friends;
  final Friend? selectedFriend;
  final Function(Friend) onSelect;
  final VoidCallback onAddNew;

  const _FriendSelectorSheet({
    required this.friends,
    this.selectedFriend,
    required this.onSelect,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Friend',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddNew,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.glassBorder),
          if (friends.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No friends yet. Add one to get started!',
                style: TextStyle(color: AppColors.textLightSecondary),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  final isSelected = selectedFriend?.id == friend.id;
                  return ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? AppColors.primaryGradient
                            : null,
                        color: isSelected ? null : AppColors.darkCardLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          friend.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.textLight
                                : AppColors.textLightSecondary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      friend.name,
                      style: const TextStyle(color: AppColors.textLight),
                    ),
                    subtitle: friend.phone != null
                        ? Text(
                            friend.phone!,
                            style: const TextStyle(
                              color: AppColors.textLightSecondary,
                            ),
                          )
                        : null,
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.accent,
                          )
                        : null,
                    onTap: () => onSelect(friend),
                  );
                },
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
