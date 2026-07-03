import 'dart:ui';

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_state_widgets.dart';
import '../core/widgets/app_text_field.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _confirmCtrl;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _confirmCtrl = TextEditingController();
  }

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

    if (username.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      setState(() {
        _errorMessage = "All field must be filled";
      });
      return;
    }

    if (password != confirm) {
      setState(() {
        _errorMessage = "Passwords do not match";
      });
      return;
    }

    if (!_agreeTerms) {
      setState(() {
        _errorMessage = "Please agree to Terms & Conditions";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.register(username, password);

      if (!mounted) return;

      if (result["status"] == "ok") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Registration successful!"),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result["message"] ?? "Registration failed";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildBackground(),
          _buildOverlay(),
          _buildRegisterCard(screenHeight),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset(
        "lib/assets/images/register_bg.jpg",
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(.15),
              Colors.black.withOpacity(.35),
              Colors.black.withOpacity(.45),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterCard(double screenHeight) {
    return SafeArea(
      child: SingleChildScrollView(
        child: SizedBox(
          height: screenHeight,
          child: Column(
            children: [
              const Spacer(),
              _buildGlassCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(38),
        topRight: Radius.circular(38),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(28, 34, 28, 30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(38),
              topRight: Radius.circular(38),
            ),
            border: Border.all(color: Colors.white.withOpacity(.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildUsernameField(),
              const SizedBox(height: 18),
              _buildPasswordField(),
              const SizedBox(height: 18),
              _buildConfirmPasswordField(),
              const SizedBox(height: 18),
              _buildTermsCheckbox(),
              const SizedBox(height: 20),
              _buildErrorBanner(),
              _buildCreateButton(),
              const SizedBox(height: 28),
              _buildDivider(),
              const SizedBox(height: 24),
              _buildSocialLogin(),
              const SizedBox(height: 30),
              _buildFooter(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sign Up",
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Create your StayMap account",
          style: TextStyle(
            color: Colors.white.withOpacity(.9),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.35)),
      ),
      child: AppTextField(
        controller: _usernameCtrl,
        hint: "Username",
        prefixIcon: Icons.person_outline,
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.35)),
      ),
      child: AppTextField(
        controller: _passwordCtrl,
        hint: "Password",
        prefixIcon: Icons.lock_outline,
        obscureText: _obscurePassword,
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.35)),
      ),
      child: AppTextField(
        controller: _confirmCtrl,
        hint: "Confirm Password",
        prefixIcon: Icons.lock_outline,
        obscureText: _obscureConfirm,
        textInputAction: TextInputAction.done,
        onSubmit: () => _register(),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          icon: Icon(
            _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: _agreeTerms,
            activeColor: AppColors.primary,
            side: const BorderSide(color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            onChanged: (value) => setState(() => _agreeTerms = value ?? false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "I agree to the Terms & Conditions",
            style: TextStyle(
              color: Colors.white.withOpacity(.95),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    if (_errorMessage == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        ErrorBanner(message: _errorMessage!),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: AppButton(
        label: "Create Account",
        onPressed: _register,
        isLoading: _isLoading,
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.white.withOpacity(.30)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "Or sign up with",
            style: TextStyle(color: Colors.white.withOpacity(.85)),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.white.withOpacity(.30)),
        ),
      ],
    );
  }

  Widget _buildSocialLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _SocialIconButton(icon: Icons.g_mobiledata, onTap: null),
        const SizedBox(width: 14),
        const _SocialIconButton(icon: Icons.facebook, onTap: null),
        const SizedBox(width: 14),
        const _SocialIconButton(icon: Icons.apple, onTap: null),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(color: Colors.white.withOpacity(.85)),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          child: const Text(
            "Sign In",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _SocialIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(.35)),
        ),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(.85),
          size: 24,
        ),
      ),
    );
  }
}
                            