import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String username;

  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _newUsernameCtrl = TextEditingController();
  bool _isChangingPassword = false;
  bool _isChangingUsername = false;
  bool _obscureOld = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _newUsernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_oldPasswordCtrl.text.isEmpty || _newPasswordCtrl.text.isEmpty) {
      _showSnackbar('Semua field wajib diisi', isError: true);
      return;
    }
    if (_newPasswordCtrl.text.length < 6) {
      _showSnackbar('Password baru minimal 6 karakter', isError: true);
      return;
    }
    setState(() => _isChangingPassword = true);
    final result = await ApiService.updatePassword(
      widget.username,
      _oldPasswordCtrl.text.trim(),
      _newPasswordCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isChangingPassword = false);
    if (result['status'] == 'ok') {
      _oldPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      Navigator.pop(context); // tutup bottom sheet
      _showSnackbar('Password berhasil diubah!');
    } else {
      _showSnackbar(result['message'] ?? 'Gagal mengubah password', isError: true);
    }
  }

  Future<void> _changeUsername() async {
    if (_newUsernameCtrl.text.trim().isEmpty) {
      _showSnackbar('Username baru wajib diisi', isError: true);
      return;
    }
    setState(() => _isChangingUsername = true);
    final result = await ApiService.updateUsername(
      widget.username,
      _newUsernameCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isChangingUsername = false);
    if (result['status'] == 'ok') {
      _newUsernameCtrl.clear();
      Navigator.pop(context);
      _showSnackbar('Username berhasil diubah! Silakan login ulang.');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } else {
      _showSnackbar(result['message'] ?? 'Gagal mengubah username', isError: true);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF2D8B6F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Helper widget untuk TextField pada BottomSheet
  Widget _buildBottomSheetTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Color(0xFF8899A6), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF2D8B6F), size: 22),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2D8B6F), width: 1.5),
        ),
      ),
    );
  }

  void _showChangePasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubah Password',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 24),
            _buildBottomSheetTextField(
              controller: _oldPasswordCtrl,
              labelText: 'Password Lama',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureOld,
              suffixIcon: IconButton(
                icon: Icon(_obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFFAAAAAA)),
                onPressed: () => setState(() => _obscureOld = !_obscureOld),
              ),
            ),
            const SizedBox(height: 16),
            _buildBottomSheetTextField(
              controller: _newPasswordCtrl,
              labelText: 'Password Baru',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureNew,
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFFAAAAAA)),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isChangingPassword ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D8B6F),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isChangingPassword
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Simpan Password',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeUsernameSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubah Username',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Setelah ubah username, kamu akan diminta login ulang.',
              style: TextStyle(color: Color(0xFF8899A6), fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildBottomSheetTextField(
              controller: _newUsernameCtrl,
              labelText: 'Username Baru',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isChangingUsername ? null : _changeUsername,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D8B6F),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isChangingUsername
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Simpan Username',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        content: const Text('Yakin ingin keluar?', style: TextStyle(color: Color(0xFF555555))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF8899A6), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)), // Soft red
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Cream beige background
      body: CustomScrollView(
        slivers: [
          // ─── Header ────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF2D8B6F), // Deep green
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFF2D8B6F),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(4), // Memberikan efek border tipis
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: const Color(0xFFF5F5DC), // Cream color avatar
                        child: Text(
                          widget.username.isNotEmpty
                              ? widget.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D8B6F), // Deep green text
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.username,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Pengaturan Akun ───────────────
                  const Text(
                    'Pengaturan Akun',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8899A6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _menuCard(
                    icon: Icons.person_outline,
                    label: 'Ubah Username',
                    onTap: _showChangeUsernameSheet,
                  ),
                  _menuCard(
                    icon: Icons.lock_outline,
                    label: 'Ubah Password',
                    onTap: _showChangePasswordSheet,
                  ),

                  const SizedBox(height: 28),
                  
                  // ─── Lainnya ───────────────────────
                  const Text(
                    'Lainnya',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8899A6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _menuCard(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    color: const Color(0xFFDC2626), // Soft red
                    onTap: _showLogoutDialog,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF2D8B6F), // Default deep green
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color == const Color(0xFFDC2626)
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF1A1A1A),
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: const Color(0xFF8899A6).withValues(alpha: 0.5), size: 24),
          ],
        ),
      ),
    );
  }
}