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
        backgroundColor: isError ? const Color(0xFFFF5E1F) : const Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showChangePasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ubah Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C2833))),
            const SizedBox(height: 20),
            TextField(
              controller: _oldPasswordCtrl,
              obscureText: _obscureOld,
              decoration: InputDecoration(
                labelText: 'Password Lama',
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00A3E4)),
                suffixIcon: IconButton(
                  icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF7F8C8D)),
                  onPressed: () => setState(() => _obscureOld = !_obscureOld),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF00A3E4), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _newPasswordCtrl,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00A3E4)),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF7F8C8D)),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF00A3E4), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isChangingPassword ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A3E4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isChangingPassword
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan Password',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ubah Username',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C2833))),
            const SizedBox(height: 8),
            const Text('Setelah ubah username, kamu akan diminta login ulang.',
                style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: _newUsernameCtrl,
              decoration: InputDecoration(
                labelText: 'Username Baru',
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF00A3E4)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF00A3E4), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isChangingUsername ? null : _changeUsername,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A3E4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isChangingUsername
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan Username',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5E1F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: CustomScrollView(
        slivers: [
          // ─── Header ────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF00A3E4),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00A3E4), Color(0xFF0077B6)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        widget.username.isNotEmpty
                            ? widget.username[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Pengaturan Akun ───────────────
                  const Text('Pengaturan Akun',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7F8C8D),
                          letterSpacing: 0.5)),
                  const SizedBox(height: 10),

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

                  const SizedBox(height: 20),
                  const Text('Lainnya',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7F8C8D),
                          letterSpacing: 0.5)),
                  const SizedBox(height: 10),

                  _menuCard(
                    icon: Icons.logout,
                    label: 'Logout',
                    color: const Color(0xFFFF5E1F),
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
    Color color = const Color(0xFF00A3E4),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color == const Color(0xFFFF5E1F)
                        ? const Color(0xFFFF5E1F)
                        : const Color(0xFF1C2833))),
            const Spacer(),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}