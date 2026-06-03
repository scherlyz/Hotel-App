import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A3E4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00A3E4),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A3E4),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF00A3E4), width: 2),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String username;
  final bool isAdmin;

  const MainScreen({
    super.key,
    required this.username,
    this.isAdmin = false,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _locationText = 'Mendapatkan lokasi...';
  bool _locationLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationText = 'GPS tidak aktif';
          _locationLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationText = 'Izin lokasi ditolak';
            _locationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText = 'Aktifkan izin lokasi di Settings';
          _locationLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

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
    } catch (e) {
      setState(() {
        _locationText = 'Gagal mendapatkan lokasi';
        _locationLoading = false;
      });
    }
  }

  List<Widget> get _screens => widget.isAdmin
      ? [
          HomeScreen(username: widget.username, isAdmin: true),
          const AdminScreen(),
          ProfileScreen(username: widget.username),
        ]
      : [
          HomeScreen(username: widget.username, isAdmin: false),
          ProfileScreen(username: widget.username),
        ];

  List<NavigationDestination> get _destinations => widget.isAdmin
      ? const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Jelajahi',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Input Data',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ]
      : const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Jelajahi',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          // ─── Header ──────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF00A3E4),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Kiri: Halo + Lokasi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Halo username
                      Row(
                        children: [
                          const Text(
                            'Halo, ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            widget.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Admin',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Lokasi
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: Colors.white, size: 15),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _locationLoading
                                ? Row(
                                    children: [
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                            color: Colors.white70, strokeWidth: 2),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text('Mendapatkan lokasi...',
                                          style: TextStyle(
                                              color: Colors.white70, fontSize: 13)),
                                    ],
                                  )
                                : Text(
                                    _locationText,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Kanan: Tombol Favorit
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FavoritesScreen(username: widget.username),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Body ─────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),

      // ─── Bottom Nav ───────────────────────────────────
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF00A3E4).withValues(alpha: 0.15),
        destinations: _destinations,
      ),
    );
  }
}