import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/common/common.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pinController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _setupPin = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.register(
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      pin: _setupPin ? _pinController.text : null,
    );

    if (!mounted) return;

    if (success) {
      CustomSnackBar.showSuccess(
        context,
        message: 'Account created successfully!',
      );
      Navigator.of(context).pushReplacementNamed(Routes.dashboard);
    } else {
      CustomSnackBar.showError(
        context,
        message: authProvider.error ?? 'Registration failed. Please try again.',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 40),
                      _buildRegistrationForm(),
                      const SizedBox(height: 24),
                      _buildPinSetup(),
                      const SizedBox(height: 32),
                      _buildRegisterButton(),
                      const SizedBox(height: 16),
                      _buildLoginOption(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryStart.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            size: 36,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Create Account',
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start your journey to financial freedom',
          style: TextStyle(
            color: AppColors.textLightSecondary.withOpacity(0.8),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      children: [
        CustomTextField(
          controller: _fullNameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          prefixIcon: Icons.badge_outlined,
          validator: validateName,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _usernameController,
          label: 'Username',
          hint: 'Choose a username',
          prefixIcon: Icons.person_outline,
          validator: validateUsername,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Create a password',
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          showPasswordToggle: true,
          validator: validatePassword,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Confirm your password',
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          showPasswordToggle: true,
          validator: (value) => validateConfirmPassword(
            value,
            _passwordController.text,
          ),
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildPinSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PIN toggle
        GestureDetector(
          onTap: () {
            setState(() => _setupPin = !_setupPin);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _setupPin
                    ? AppColors.accent.withOpacity(0.5)
                    : AppColors.glassBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _setupPin
                        ? AppColors.accent.withOpacity(0.2)
                        : AppColors.glassBorder.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.pin,
                    color: _setupPin
                        ? AppColors.accent
                        : AppColors.textLightSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Setup Quick PIN',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Use a 4-digit PIN for faster login',
                        style: TextStyle(
                          color: AppColors.textLightSecondary.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _setupPin,
                  onChanged: (value) {
                    setState(() => _setupPin = value);
                  },
                  activeColor: AppColors.accent,
                ),
              ],
            ),
          ),
        ),
        // PIN input
        if (_setupPin) ...[
          const SizedBox(height: 16),
          CustomTextField(
            controller: _pinController,
            label: 'PIN',
            hint: 'Enter 4-digit PIN',
            prefixIcon: Icons.dialpad,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            validator: _setupPin ? validatePin : null,
            textInputAction: TextInputAction.done,
          ),
        ],
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'Create Account',
            onPressed: authProvider.isLoading ? null : _handleRegister,
            isLoading: authProvider.isLoading,
            icon: Icons.person_add,
          ),
        );
      },
    );
  }

  Widget _buildLoginOption() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: TextStyle(
              color: AppColors.textLightSecondary.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacementNamed(Routes.login);
            },
            child: const Text(
              'Sign In',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
