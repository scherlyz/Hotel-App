import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:geocoding/geocoding.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/favorites_service.dart';
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
  FavoritesService? _favoritesService;

  bool get _isGuest => widget.isGuest;

  @override
  void initState() {
    super.initState();
    if (!_isGuest) {
      _favoritesService = FavoritesService(username: widget.username);
    }
    _initLocation();
  }

  @override
  void dispose() {
    _favoritesService?.dispose();
    super.dispose();
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
      favoritesService: _favoritesService,
    );

    if (widget.isAdmin) {
      return [
        home,
        FavoritesScreen(
          username: widget.username,
          isGuest: false,
          favoritesService: _favoritesService,
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
        favoritesService: _favoritesService,
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
              const Text('Not Logged In',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              const Text(
                'Login to access your profile,\nsave favorites, and write reviews.',
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
                  child: const Text('Login / Sign Up',
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