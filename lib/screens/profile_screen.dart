import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  final bool isGuest;
  final bool isAdmin;

  const ProfileScreen({
    super.key,
    required this.username,
    this.isGuest = false,
    this.isAdmin = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Sama seperti hero image di HomeScreen supaya header konsisten di seluruh app.
  static const String _heroImageUrl = 'lib/assets/images/hero_bg.png';

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

  // ─── Actions ────────────────────────────────────────────────────────────

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
      Navigator.pop(context);
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
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature akan segera hadir'),
        backgroundColor: AppColors.textMuted,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Shared text field ──────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 22),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }

  void _showChangePasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Text('Ubah Password',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text('Gunakan password baru minimal 6 karakter.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _oldPasswordCtrl,
                  labelText: 'Password Lama',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureOld,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureOld
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textHint),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _newPasswordCtrl,
                  labelText: 'Password Baru',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureNew,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureNew
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textHint),
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
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isChangingPassword
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Simpan Password',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showChangeUsernameSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Text('Ubah Username',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text('Setelah ubah username, kamu akan diminta login ulang.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                const SizedBox(height: 24),
                _buildTextField(
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
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isChangingUsername
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Simpan Username',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: Text(
            widget.isGuest ? 'Keluar dari mode guest?' : 'Yakin ingin keluar?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(
                    color: AppColors.textMuted, fontWeight: FontWeight.bold)),
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── Hero header — foto fixed di belakang, tidak ikut scroll ──────────
  Widget _buildHeroHeader() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            _heroImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, error, __) {
              debugPrint('Hero image failed: $error');
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xFF0F2E28)],
                  ),
                ),
              );
            },
          ),
        ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: .35),
                    Colors.black.withValues(alpha: .55),
                    Colors.black.withValues(alpha: .78),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              left: 24,
              right: 24,
              bottom: 28,
            ),
            child: Column(
              children: [
                const Text('Profil Saya',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: .4), width: 1.2),
                  ),
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.username.isNotEmpty
                          ? widget.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3),
                      ),
                    ),
                    if (widget.isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('Admin',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                      ),
                    ],
                    if (widget.isGuest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('Guest',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isGuest
                      ? 'Login untuk akses penuh fitur akun'
                      : '@${widget.username}',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double headerHeight = (screenHeight * 0.30).clamp(140.0, 300.0);
    final double initialSheetSize =
        (1 - (headerHeight - 16) / screenHeight).clamp(0.55, 0.85);
    final double safeTopGap = MediaQuery.of(context).padding.top + 20;
    final double maxSheetSize =
        (1 - safeTopGap / screenHeight).clamp(initialSheetSize, 0.95);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ─── Foto hero, fixed di belakang (tidak ikut scroll) ──────
          SizedBox(
            height: headerHeight,
            width: double.infinity,
            child: _buildHeroHeader(),
          ),

          // ─── Form profil — bisa ditarik naik/turun seperti detail screen ──
          DraggableScrollableSheet(
            initialChildSize: initialSheetSize,
            minChildSize: initialSheetSize,
            maxChildSize: maxSheetSize,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  if (widget.isGuest) _buildGuestBanner(),

                  _sectionLabel('PROFIL'),
                  _buildGroupedCard([
                    _menuTile(
                      icon: Icons.badge_outlined,
                      label: 'Edit Profile',
                      subtitle: 'Foto, nama tampilan & bio',
                      onTap: () => _showComingSoon('Edit profile'),
                      comingSoon: true,
                    ),
                  ]),

                  _sectionLabel('AKUN'),
                  _buildGroupedCard([
                    _menuTile(
                      icon: Icons.person_outline,
                      label: 'Ubah Username',
                      subtitle: widget.isGuest ? null : widget.username,
                      onTap: widget.isGuest
                          ? () => _showComingSoon('Ubah username')
                          : _showChangeUsernameSheet,
                      disabled: widget.isGuest,
                    ),
                    _menuTile(
                      icon: Icons.lock_outline,
                      label: 'Ubah Password',
                      subtitle: '••••••••',
                      onTap: widget.isGuest
                          ? () => _showComingSoon('Ubah password')
                          : _showChangePasswordSheet,
                      disabled: widget.isGuest,
                    ),
                  ]),

                  _sectionLabel('PRIVASI & PREFERENSI'),
                  _buildGroupedCard([
                    _menuTile(
                      icon: Icons.shield_outlined,
                      label: 'Privasi & Keamanan',
                      onTap: () => _showComingSoon('Privasi & Keamanan'),
                      comingSoon: true,
                    ),
                    _menuTile(
                      icon: Icons.tune_rounded,
                      label: 'Preferensi',
                      onTap: () => _showComingSoon('Preferensi'),
                      comingSoon: true,
                    ),
                    _menuTile(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notifikasi',
                      onTap: () => _showComingSoon('Pengaturan notifikasi'),
                      comingSoon: true,
                    ),
                    _menuTile(
                      icon: Icons.language_rounded,
                      label: 'Bahasa',
                      onTap: () => _showComingSoon('Pengaturan bahasa'),
                      comingSoon: true,
                    ),
                  ]),

                  _sectionLabel('LAINNYA'),
                  _buildGroupedCard([
                    _menuTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Pusat Bantuan',
                      onTap: () => _showComingSoon('Pusat bantuan'),
                      comingSoon: true,
                    ),
                    _menuTile(
                      icon: Icons.info_outline_rounded,
                      label: 'Tentang Aplikasi',
                      onTap: () => _showComingSoon('Tentang aplikasi'),
                      comingSoon: true,
                    ),
                  ]),

                  const SizedBox(height: 12),
                  _buildGroupedCard([
                    _menuTile(
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      color: AppColors.error,
                      onTap: _showLogoutDialog,
                      showChevron: false,
                    ),
                  ]),

                  const SizedBox(height: 20),
                  Center(
                    child: Text('Versi 1.0.0',
                        style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: .6),
                            fontSize: 12)),
                  ),
                ],
              ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── UI helpers ─────────────────────────────────────────────────────────

  Widget _buildGuestBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: .15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Kamu sedang login sebagai Guest. Login untuk mengakses semua fitur akun.',
              style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: .85),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.8)),
    );
  }

  Widget _buildGroupedCard(List<Widget> tiles) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i != tiles.length - 1)
              const Divider(height: 1, indent: 60, color: AppColors.border),
          ],
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? subtitle,
    Color color = AppColors.primary,
    bool comingSoon = false,
    bool disabled = false,
    bool showChevron = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: (disabled ? AppColors.textMuted : color)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon,
                    color: disabled ? AppColors.textMuted : color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(label,
                            style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: disabled
                                    ? AppColors.textMuted
                                    : (color == AppColors.error
                                        ? AppColors.error
                                        : AppColors.textPrimary))),
                        if (comingSoon) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Segera',
                                style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMuted)),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
              ),
              if (showChevron)
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    size: 22),
            ],
          ),
        ),
      ),
    );
  }
}