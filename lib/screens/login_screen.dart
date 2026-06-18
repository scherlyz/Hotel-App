import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/widgets/app_text_field.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_state_widgets.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Username and password required');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final result = await ApiService.postRequest('login', {
        'username': username,
        'password': password,
      });

      if (!mounted) return;

      if (result['status'] == 'ok') {
        final role = result['data']?['role']?.toString() ?? 'user';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainScreen(username: username, isAdmin: role == 'admin'),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Login failed';
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
              _AppLogo(icon: Icons.travel_explore),
              const SizedBox(height: 28),
              const _AuthHeader(
                title: 'Welcome Back',
                subtitle: 'Find the best places for your travels',
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
                textInputAction: TextInputAction.done,
                onSubmit: _login,
                suffixIcon: _TogglePasswordButton(
                  obscure: _obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 22,
                        width: 22,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (val) => setState(() => _rememberMe = val ?? false),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Remember me',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  const Text('Forget Password',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                ErrorBanner(message: _errorMessage!),
                const SizedBox(height: 20),
              ],

              AppButton(label: 'Login', onPressed: _login, isLoading: _isLoading),
              const SizedBox(height: 24),

              const _Divider(),
              const SizedBox(height: 24),

              _SocialButton(
                icon: Icons.g_mobiledata,
                label: 'Log in with Google',
                onPressed: () {},
              ),
              const SizedBox(height: 12),
              _SocialButton(
                icon: Icons.apple,
                label: 'Log in with Apple',
                onPressed: () {},
              ),
              const SizedBox(height: 32),

              _AuthFooter(
                message: "Don't have an account? ",
                actionLabel: 'Sign up',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
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

// ─── Shared Auth Widgets ───────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  final IconData icon;
  const _AppLogo({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
    return Column(
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.5)),
      ],
    );
  }
}

class _TogglePasswordButton extends StatelessWidget {
  final bool obscure;
  final VoidCallback onToggle;
  const _TogglePasswordButton({required this.obscure, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.textHint,
        size: 20,
      ),
      onPressed: onToggle,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.border)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('or', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
        ),
        Expanded(child: Container(height: 1, color: AppColors.border)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _SocialButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24, color: AppColors.textSecondary),
        label: Text(label,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message, style: const TextStyle(color: Color(0xFF888888), fontSize: 14)),
        GestureDetector(
          onTap: onTap,
          child: Text(actionLabel,
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ],
    );
  }
}