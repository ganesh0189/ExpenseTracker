import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/themes.dart';
import '../../models/friend.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/common/common.dart';

class AddFriendScreen extends StatefulWidget {
  final int? editFriendId;

  const AddFriendScreen({super.key, this.editFriendId});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isEditing = false;
  Friend? _existingFriend;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (widget.editFriendId != null) {
      _isEditing = true;
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      _existingFriend = friendProvider.getFriendById(widget.editFriendId!);

      if (_existingFriend != null) {
        _nameController.text = _existingFriend!.name;
        _phoneController.text = _existingFriend!.phone ?? '';
        _emailController.text = _existingFriend!.email ?? '';
        _notesController.text = _existingFriend!.notes ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveFriend() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId == null) return;

    final friendProvider = Provider.of<FriendProvider>(context, listen: false);

    final friend = Friend(
      id: _isEditing ? _existingFriend!.id : null,
      userId: userId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    bool success;
    if (_isEditing) {
      success = await friendProvider.updateFriend(friend);
    } else {
      final friendId = await friendProvider.addFriend(friend);
      success = friendId != null;
    }

    if (!mounted) return;

    if (success) {
      CustomSnackBar.showSuccess(
        context,
        message: _isEditing ? 'Friend updated' : 'Friend added',
      );
      Navigator.pop(context);
    } else {
      CustomSnackBar.showError(
        context,
        message: friendProvider.error ?? 'Failed to save friend',
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
                title: _isEditing ? 'Edit Friend' : 'Add Friend',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildAvatarSection(),
                        const SizedBox(height: 32),
                        CustomTextField(
                          controller: _nameController,
                          label: 'Name',
                          hint: 'Enter friend\'s name',
                          prefixIcon: Icons.person,
                          validator: validateName,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _phoneController,
                          label: 'Phone (Optional)',
                          hint: 'Enter phone number',
                          prefixIcon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: validatePhone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email (Optional)',
                          hint: 'Enter email address',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: validateEmail,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _notesController,
                          label: 'Notes (Optional)',
                          hint: 'Add any notes',
                          prefixIcon: Icons.notes,
                          maxLines: 3,
                        ),
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

  Widget _buildAvatarSection() {
    final name = _nameController.text;
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryStart.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        return SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: _isEditing ? 'Update Friend' : 'Add Friend',
            onPressed: friendProvider.isLoading ? null : _saveFriend,
            isLoading: friendProvider.isLoading,
          ),
        );
      },
    );
  }
}
