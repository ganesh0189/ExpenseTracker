import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/common.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _pin = [];
  final int _pinLength = 4;
  bool _hasError = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _handlePinComplete() async {
    if (_pin.length != _pinLength) return;

    final pinString = _pin.join();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.loginWithPin(pinString);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed(Routes.dashboard);
    } else {
      // Shake animation and clear PIN
      setState(() {
        _hasError = true;
        _pin.clear();
      });
      HapticFeedback.heavyImpact();
      _shakeController.forward().then((_) {
        _shakeController.reverse();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() => _hasError = false);
          }
        });
      });
    }
  }

  void _addDigit(String digit) {
    if (_pin.length < _pinLength) {
      HapticFeedback.lightImpact();
      setState(() {
        _pin.add(digit);
        _hasError = false;
      });
      if (_pin.length == _pinLength) {
        _handlePinComplete();
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _pin.removeLast();
        _hasError = false;
      });
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
              // Back button
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: AppColors.textLight,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const Spacer(),
              // Header
              _buildHeader(),
              const SizedBox(height: 40),
              // PIN dots
              _buildPinDots(),
              const Spacer(),
              // Numpad
              _buildNumpad(),
              const SizedBox(height: 32),
              // Use password option
              _buildPasswordOption(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            // User avatar
            Container(
              width: 80,
              height: 80,
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
                  authProvider.user?.fullName.substring(0, 1).toUpperCase() ?? '?',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome back,',
              style: TextStyle(
                color: AppColors.textLightSecondary.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              authProvider.user?.fullName ?? 'User',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your PIN to continue',
              style: TextStyle(
                color: AppColors.textLightSecondary.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPinDots() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value * (_shakeController.status == AnimationStatus.forward ? 1 : -1), 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _pinLength,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: index < _pin.length ? 20 : 16,
            height: index < _pin.length ? 20 : 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hasError
                  ? AppColors.error
                  : (index < _pin.length
                      ? AppColors.accent
                      : AppColors.darkCardLight),
              border: index < _pin.length
                  ? null
                  : Border.all(
                      color: _hasError
                          ? AppColors.error.withOpacity(0.5)
                          : AppColors.glassBorder,
                      width: 2,
                    ),
              boxShadow: index < _pin.length
                  ? [
                      BoxShadow(
                        color: (_hasError ? AppColors.error : AppColors.accent)
                            .withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            children: [
              _buildNumpadRow(['1', '2', '3'], authProvider.isLoading),
              const SizedBox(height: 16),
              _buildNumpadRow(['4', '5', '6'], authProvider.isLoading),
              const SizedBox(height: 16),
              _buildNumpadRow(['7', '8', '9'], authProvider.isLoading),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Empty space
                  const SizedBox(width: 72, height: 72),
                  // Zero
                  _buildNumpadButton('0', authProvider.isLoading),
                  // Backspace
                  _buildBackspaceButton(authProvider.isLoading),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNumpadRow(List<String> digits, bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) => _buildNumpadButton(digit, isLoading)).toList(),
    );
  }

  Widget _buildNumpadButton(String digit, bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : () => _addDigit(digit),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.darkCardLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.glassBorder,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 28,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _removeDigit,
      onLongPress: isLoading
          ? null
          : () {
              HapticFeedback.mediumImpact();
              setState(() => _pin.clear());
            },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.darkCardLight.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            color: AppColors.textLightSecondary,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordOption() {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(context).pushReplacementNamed(Routes.login);
      },
      icon: const Icon(
        Icons.lock_outline,
        color: AppColors.textLightSecondary,
        size: 18,
      ),
      label: const Text(
        'Use password instead',
        style: TextStyle(
          color: AppColors.textLightSecondary,
          fontSize: 14,
        ),
      ),
    );
  }
}
