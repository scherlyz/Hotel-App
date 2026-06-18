import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_screen.dart';
import 'services/location_service.dart';
import 'screens/splash_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D8B6F),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2D8B6F),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D8B6F),
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
            borderSide: const BorderSide(color: Color(0xFF2D8B6F), width: 2),
          ),
        ),
      ),
      home: const SplashScreen(),
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
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      print('[Location] Starting getLocation...');
      final coords = await getLocation();
      print('[Location] Result: $coords');

      if (coords == null) {
        print('[Location] coords is null — permission denied or GPS off');
        setState(() {
          _locationText = 'Izin lokasi ditolak';
          _locationLoading = false;
        });
        return;
      }

      _userLat = coords['lat'];
      _userLng = coords['lng'];
      print('[Location] lat: $_userLat, lng: $_userLng');

      try {
        final placemarks =
            await placemarkFromCoordinates(_userLat!, _userLng!);
        print('[Location] placemarks: $placemarks');
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            if (p.street != null && p.street!.isNotEmpty) p.street,
            if (p.subLocality != null && p.subLocality!.isNotEmpty)
              p.subLocality,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality,
          ];
          setState(() {
            _locationText =
                parts.isNotEmpty ? parts.join(', ') : 'Lokasi ditemukan';
            _locationLoading = false;
          });
        }
      } catch (e) {
        print('[Location] Geocoding error: $e');
        setState(() {
          _locationText =
              '${_userLat!.toStringAsFixed(4)}, ${_userLng!.toStringAsFixed(4)}';
          _locationLoading = false;
        });
      }
    } catch (e) {
      print('[Location] Error: $e');
      setState(() {
        _locationText = 'Gagal mendapatkan lokasi';
        _locationLoading = false;
      });
    }
  }

  List<Widget> get _screens => widget.isAdmin
      ? [
          HomeScreen(
            username: widget.username,
            isAdmin: true,
            userLat: _userLat,
            userLng: _userLng,
          ),
          const AdminScreen(),
          ProfileScreen(username: widget.username),
        ]
      : [
          HomeScreen(
            username: widget.username,
            isAdmin: false,
            userLat: _userLat,
            userLng: _userLng,
          ),
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
      backgroundColor: const Color(0xFFF5F5DC),
      body: Column(
        children: [
          // ─── Header (hanya di tab Jelajahi) ──────────
          if (_currentIndex == 0)
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF2D8B6F),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
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
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 15)),
                            Text(widget.username,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                            if (widget.isAdmin) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Admin',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: Colors.white, size: 15),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _locationLoading
                                  ? const Row(
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                              color: Colors.white70,
                                              strokeWidth: 2),
                                        ),
                                        SizedBox(width: 6),
                                        Text('Mendapatkan lokasi...',
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13)),
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
                  // Tombol Favorit — setState setelah balik dari FavoritesScreen
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FavoritesScreen(username: widget.username),
                        ),
                      );
                      // Setelah balik dari FavoritesScreen, trigger rebuild
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),

          // ─── Body ─────────────────────────────────────
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF2D8B6F).withValues(alpha: 0.15),
        destinations: _destinations,
      ),
    );
  }
}