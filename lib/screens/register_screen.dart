import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/widgets/app_text_field.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_state_widgets.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (username.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'All field must be filled');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final result = await ApiService.register(username, password);
      if (!mounted) return;

      if (result['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registration successful! Please login.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Registration failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _AppLogo(icon: Icons.person_add_rounded),
              const SizedBox(height: 28),
              const _AuthHeader(
                title: 'Create New Account',
                subtitle: 'Join and start discovering the best places for your travels',
              ),
              const SizedBox(height: 36),

              AppTextField(
                controller: _usernameCtrl,
                hint: 'Username',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _passwordCtrl,
                hint: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: _TogglePasswordButton(
                  obscure: _obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _confirmCtrl,
                hint: 'Confirm Password',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onSubmit: _register,
                suffixIcon: _TogglePasswordButton(
                  obscure: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                ErrorBanner(message: _errorMessage!),
                const SizedBox(height: 20),
              ],

              AppButton(label: 'Sign Up', onPressed: _register, isLoading: _isLoading),
              const SizedBox(height: 24),

              _AuthFooter(
                message: 'Already have an account? ',
                actionLabel: 'Log in',
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Reuse widgets dari login_screen.dart
class _AppLogo extends StatelessWidget {
  final IconData icon;
  const _AppLogo({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Icon(icon, size: 36, color: Colors.white),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _AuthHeader({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.5)),
    ]);
  }
}

class _TogglePasswordButton extends StatelessWidget {
  final bool obscure;
  final VoidCallback onToggle;
  const _TogglePasswordButton({required this.obscure, required this.onToggle});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textHint, size: 20),
      onPressed: onToggle,
    );
  }
}

class _AuthFooter extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onTap;
  const _AuthFooter({required this.message, required this.actionLabel, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(message, style: const TextStyle(color: Color(0xFF888888), fontSize: 14)),
      GestureDetector(
        onTap: onTap,
        child: Text(actionLabel, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    ]);
  }
}