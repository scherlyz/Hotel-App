import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_state_widgets.dart';
import '../core/widgets/app_text_field.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
  }

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
      setState(() => _errorMessage = 'Username dan password wajib diisi');
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
        // pushReplacement — hapus semua history (termasuk SplashScreen / stack guest)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MainScreen(
              username: username,
              isAdmin: role == 'admin',
              isGuest: false, // ← selalu false setelah login
            ),
          ),
          (_) => false,
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Login gagal';
          _isLoading = false;
        });
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
          _buildLoginCard(screenHeight),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset('lib/assets/images/login_bg.jpg', fit: BoxFit.cover),
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
              Colors.black.withValues(alpha: .15),
              Colors.black.withValues(alpha: .35),
              Colors.black.withValues(alpha: .45),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(double screenHeight) {
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
            color: Colors.white.withValues(alpha: .18),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(38),
              topRight: Radius.circular(38),
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildUsernameField(),
              const SizedBox(height: 18),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildRememberAndForgot(),
              const SizedBox(height: 22),
              _buildErrorBanner(),
              _buildLoginButton(),
              const SizedBox(height: 28),
              _buildDivider(),
              const SizedBox(height: 26),
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
        const Text('Sign In',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 40)),
        const SizedBox(height: 8),
        Text('Welcome back to StayMap',
            style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 16)),
      ],
    );
  }

  Widget _buildUsernameField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .35)),
      ),
      child: AppTextField(
        controller: _usernameCtrl,
        hint: 'Username',
        prefixIcon: Icons.person_outline,
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .35)),
      ),
      child: AppTextField(
        controller: _passwordCtrl,
        hint: 'Password',
        prefixIcon: Icons.lock_outline,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        onSubmit: _login,
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildRememberAndForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _rememberMe,
                activeColor: AppColors.primary,
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Remember me',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
        const Text('Forgot Password?',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
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

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: AppButton(label: 'Sign In', onPressed: _login, isLoading: _isLoading),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: .35))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('Or sign in with',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .85), fontSize: 14)),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: .35))),
      ],
    );
  }

  Widget _buildSocialLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialIconButton(icon: Icons.g_mobiledata, onTap: () {}),
        const SizedBox(width: 14),
        _SocialIconButton(icon: Icons.facebook, onTap: () {}),
        const SizedBox(width: 14),
        _SocialIconButton(icon: Icons.apple, onTap: () {}),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ",
            style: TextStyle(color: Colors.white.withValues(alpha: .85))),
        GestureDetector(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
          child: const Text('Sign Up',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: .30)),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}