import 'package:flutter/material.dart';
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
      setState(() => _errorMessage = 'Semua field wajib diisi');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Password tidak cocok');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password minimal 6 karakter');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final result = await ApiService.register(username, password);
      if (!mounted) return;

      if (result['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registrasi berhasil! Silakan login.'),
            backgroundColor: const Color(0xFF2ECC71),
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
          _errorMessage = result['message'] ?? 'Registrasi gagal';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputAction action = TextInputAction.next,
    VoidCallback? onSubmit,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: action,
      onSubmitted: onSubmit != null ? (_) => onSubmit() : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF00A3E4)),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF7F8C8D),
                ),
                onPressed: onToggleObscure,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00A3E4), width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00A3E4),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ────────────────────────────────
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.person_add_rounded, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Buat Akun Baru',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Text(
                      'Bergabung dan mulai jelajahi',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Form ──────────────────────────────────
            Expanded(
              flex: 4,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Daftar',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C2833),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Isi data berikut untuk membuat akun',
                        style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      _buildTextField(
                        controller: _usernameCtrl,
                        label: 'Username',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 14),

                      _buildTextField(
                        controller: _passwordCtrl,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        obscure: _obscurePassword,
                        onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      const SizedBox(height: 14),

                      _buildTextField(
                        controller: _confirmCtrl,
                        label: 'Konfirmasi Password',
                        icon: Icons.lock_outline,
                        obscure: _obscureConfirm,
                        onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        action: TextInputAction.done,
                        onSubmit: _register,
                      ),

                      // Error
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFF5E1F).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFFF5E1F), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_errorMessage!,
                                    style: const TextStyle(color: Color(0xFFFF5E1F), fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A3E4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Daftar Sekarang',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Sudah punya akun? ',
                              style: TextStyle(color: Color(0xFF7F8C8D))),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            ),
                            child: const Text(
                              'Masuk',
                              style: TextStyle(
                                color: Color(0xFF00A3E4),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}