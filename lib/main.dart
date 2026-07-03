import 'package:flutter/material.dart';
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
      title: 'Wisata & Hotel App',
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
  String _locationText = 'Mendapatkan lokasi...';
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
          _locationText = 'Izin lokasi ditolak';
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
            _locationText = parts.isNotEmpty ? parts.join(', ') : 'Lokasi ditemukan';
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
        _locationText = 'Gagal mendapatkan lokasi';
        _locationLoading = false;
      });
    }
  }

  // ─── Screens ──────────────────────────────────────────────────────────────

  List<Widget> get _screens {
    final home = HomeScreen(
      username: widget.username,
      isAdmin: widget.isAdmin,
      isGuest: _isGuest,
      userLat: _userLat,
      userLng: _userLng,
    );

    if (widget.isAdmin) {
      return [home, const AdminScreen(), ProfileScreen(username: widget.username, isGuest: false)];
    }
    return [home, _isGuest ? const _GuestProfilePrompt() : ProfileScreen(username: widget.username, isGuest: false)];
  }

  List<NavigationDestination> get _destinations => widget.isAdmin
      ? const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Jelajahi'),
          NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings), label: 'Input Data'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ]
      : const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Jelajahi'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ];

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (_currentIndex == 0) _buildHeader(),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        destinations: _destinations,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20, right: 20, bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Halo, ',
                        style: TextStyle(color: Colors.white70, fontSize: 15)),
                    Text(widget.username,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    if (widget.isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('Admin',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                      ),
                    ],
                    if (_isGuest) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('Tamu',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.white, size: 15),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _locationLoading
                          ? const Row(children: [
                              SizedBox(
                                width: 12, height: 12,
                                child: CircularProgressIndicator(
                                    color: Colors.white70, strokeWidth: 2),
                              ),
                              SizedBox(width: 6),
                              Text('Mendapatkan lokasi...',
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ])
                          : Text(_locationText,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Tombol Favorit ───────────────────────────
          GestureDetector(
            onTap: () async {
              // Guest tetap bisa buka FavoritesScreen (tapi akan tampil kosong + prompt login)
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FavoritesScreen(
                    username: widget.username,
                    isGuest: _isGuest,
                  ),
                ),
              );
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Guest Profile Prompt ─────────────────────────────────────────────────
class _GuestProfilePrompt extends StatelessWidget {
  const _GuestProfilePrompt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline_rounded,
                    size: 56, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text('Belum Login',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              const Text(
                'Login untuk mengakses profil,\nmenyimpan favorit, dan menulis ulasan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: AppColors.textMuted, height: 1.6),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Login / Daftar',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}