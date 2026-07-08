import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:geocoding/geocoding.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/location_service.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel & Hotel App',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [FavoritesScreen.routeObserver],
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String username;
  final bool isAdmin;
  final bool isGuest;

  const MainScreen({
    super.key,
    required this.username,
    this.isAdmin = false,
    this.isGuest = false,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();

}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _locationText = 'Getting location...';
  bool _locationLoading = true;
  double? _userLat;
  double? _userLng;

  bool get _isGuest => widget.isGuest;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final coords = await getLocation();
      if (coords == null) {
        setState(() {
          _locationText = 'Location permission denied';
          _locationLoading = false;
        });
        return;
      }
      _userLat = coords['lat'];
      _userLng = coords['lng'];
      try {
        final placemarks = await placemarkFromCoordinates(_userLat!, _userLng!);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            if (p.street != null && p.street!.isNotEmpty) p.street,
            if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality,
          ];
          setState(() {
            _locationText = parts.isNotEmpty ? parts.join(', ') : 'Location found';
            _locationLoading = false;
          });
        }
      } catch (_) {
        setState(() {
          _locationText = '${_userLat!.toStringAsFixed(4)}, ${_userLng!.toStringAsFixed(4)}';
          _locationLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _locationText = 'Failed to get location';
        _locationLoading = false;
      });
    }
  }

  // ─── Screens ──────────────────────────────────────────────────────────

  List<Widget> get _screens {
    final home = HomeScreen(
      username: widget.username,
      isAdmin: widget.isAdmin,
      isGuest: _isGuest,
      userLat: _userLat,
      userLng: _userLng,
      locationText: _locationText,
      locationLoading: _locationLoading,
    );

    if (widget.isAdmin) {
      return [
        home,
        FavoritesScreen(
          username: widget.username,
          isGuest: false,
          onBackToHome: () => setState(() => _currentIndex = 0),
        ),
        const AdminScreen(),
        ProfileScreen(username: widget.username, isGuest: false),
      ];
    }

    return [
      home,
      FavoritesScreen(
        username: widget.username,
        isGuest: _isGuest,
        onBackToHome: () => setState(() => _currentIndex = 0),
      ),
      _isGuest
          ? const _GuestProfilePrompt()
          : ProfileScreen(username: widget.username, isGuest: false),
    ];
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
          // IndexedStack menjaga semua tab tetap "hidup" di memori —
          // cuma disembunyikan/ditampilkan, bukan dibongkar-pasang.
          // Ini yang mencegah FavoritesScreen (dan tab lain) reload
          // dari nol setiap kali pindah tab.
          child: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ),

          // Floating glass navbar
          Positioned(
          left: 0,
              right: 0,
              bottom: 24,
              child: SafeArea(
                top: false,
                child: Center(
                  child: SizedBox(
                    width: 320,
                    child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .85), // hijau, transparan dikit
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navItem(Icons.home_rounded, 0),
                  _navItem(Icons.favorite_rounded, 1),
                  if (widget.isAdmin) _navItem(Icons.add_business_rounded, 2),
                  _navItem(Icons.person_rounded, widget.isAdmin ? 3 : 2),
                ],
              ),
            ),
      ),
    ),
  ),
),
        ],
      ),
    );
  }
Widget _navItem(IconData icon, int index) {
  final selected = _currentIndex == index;

  return InkWell(
    borderRadius: BorderRadius.circular(32),
    onTap: () => setState(() => _currentIndex = index),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? Colors.white : Colors.transparent, // solid putih, bukan transparan/blur
      ),
      child: Icon(
        icon,
        color: selected ? AppColors.primary : Colors.white,
        size: 30,
      ),
    ),
  );
}
}

// ─── Guest Profile Prompt ─────────────────────────────────────────────
// Tampilan disamakan dengan ProfileScreen (hero header + draggable sheet),
// tapi logic-nya tetap sederhana: cuma 1 tombol menuju LoginScreen.
class _GuestProfilePrompt extends StatelessWidget {
  const _GuestProfilePrompt();

  static const String _heroImageUrl = 'lib/assets/images/hero_bg.png';

  // ─── Hero header — pola sama persis dengan ProfileScreen ─────────────
  Widget _buildHeroHeader(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            _heroImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, error, __) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, Color(0xFF0F2E28)],
                ),
              ),
            ),
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
                child: const CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_rounded,
                      size: 42, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Guest',
                      style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3)),
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
              ),
              const SizedBox(height: 4),
              const Text(
                'Login untuk akses penuh fitur akun',
                style: TextStyle(
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
    final double headerHeight = (screenHeight * 0.28).clamp(180.0, 270.0);
    final double initialSheetSize =
        (1 - (headerHeight - 28) / screenHeight).clamp(0.72, 0.9);
    final double safeTopGap = MediaQuery.of(context).padding.top + 76;
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
            child: _buildHeroHeader(context),
          ),

          // ─── Sheet — bisa ditarik naik/turun, sama seperti ProfileScreen ──
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
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 32),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline_rounded,
                          size: 48, color: AppColors.primary),
                    ),
                    const SizedBox(height: 22),
                    const Text('Belum Login',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    const Text(
                      'Login untuk mengakses profil, menyimpan\nfavorit, dan menulis ulasan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textMuted,
                          height: 1.55),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Login / Daftar',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text('Versi 1.0.0',
                          style: TextStyle(
                              color:
                                  AppColors.textMuted.withValues(alpha: .6),
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
}