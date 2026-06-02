import 'package:flutter/material.dart';
import '../models/place.dart';
import '../services/api_service.dart';
import '../widgets/place_card.dart';
import 'detail_screen.dart';
import 'favorites_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Place> _allPlaces = [];
  List<Place> _filteredPlaces = [];
  List<String> _categories = ['Semua'];
  Set<int> _favoriteIds = {};
  String _selectedCategory = 'Semua';
  bool _isLoading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final results = await Future.wait([
      ApiService.getAllPlaces(),
      ApiService.getCategories(),
      ApiService.getFavorites(widget.username),
    ]);

    final placesResult = results[0];
    final catResult = results[1];
    final favResult = results[2];

    if (!mounted) return;

    if (placesResult['status'] == 'ok') {
      final List data = placesResult['data'] ?? [];
      _allPlaces = data.map((e) => Place.fromJson(e)).toList();
      _filteredPlaces = List.from(_allPlaces);
    } else {
      _error = placesResult['message'] ?? 'Gagal memuat data';
    }

    if (catResult['status'] == 'ok') {
      final List cats = catResult['data'] ?? [];
      _categories = ['Semua', ...cats.map((e) => e['name'].toString())];
    }

    if (favResult['status'] == 'ok') {
      final List favs = favResult['data'] ?? [];
      _favoriteIds = favs.map<int>((e) => int.tryParse(e['id'].toString()) ?? 0).toSet();
    }

    setState(() => _isLoading = false);
  }

  void _filterPlaces() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredPlaces = _allPlaces.where((p) {
        final matchCat =
            _selectedCategory == 'Semua' || p.category == _selectedCategory;
        final matchQuery =
            query.isEmpty || p.name.toLowerCase().contains(query) || p.address.toLowerCase().contains(query);
        return matchCat && matchQuery;
      }).toList();
    });
  }

  Future<void> _toggleFavorite(Place place) async {
    final result = await ApiService.toggleFavorite(place.id, widget.username);
    if (result['status'] == 'ok') {
      setState(() {
        if (result['favorited'] == true) {
          _favoriteIds.add(place.id);
        } else {
          _favoriteIds.remove(place.id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Sangat cerah/bersih
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF00A3E4), // Blue Traveloka
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Halo,',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                          Text(
                            widget.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Favorit
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FavoritesScreen(username: widget.username),
                          ),
                        ).then((_) => _loadData()), // Reload favs
                        icon: const Icon(Icons.favorite_rounded, color: Colors.white),
                      ),
                      // Logout
                      IconButton(
                        onPressed: () => _showLogoutDialog(),
                        icon: const Icon(Icons.logout_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => _filterPlaces(),
                      decoration: const InputDecoration(
                        hintText: 'Mau jalan-jalan kemana?',
                        hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF00A3E4)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Filter kategori ───────────────────────
            SizedBox(
              height: 64,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      _filterPlaces();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF00A3E4) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected ? const Color(0xFF00A3E4) : const Color(0xFFE0E0E0),
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00A3E4).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: selected ? Colors.white : const Color(0xFF7F8C8D),
                            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ─── Jumlah hasil ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${_filteredPlaces.length} destinasi ditemukan',
                    style: const TextStyle(
                        color: Color(0xFF7F8C8D),
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // ─── List tempat ───────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00A3E4)))
                  : _error != null
                      ? _buildError()
                      : _filteredPlaces.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              color: const Color(0xFF00A3E4),
                              onRefresh: _loadData,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(top: 8, bottom: 24),
                                itemCount: _filteredPlaces.length,
                                itemBuilder: (_, i) {
                                  final place = _filteredPlaces[i];
                                  return PlaceCard(
                                    place: place,
                                    isFavorite: _favoriteIds.contains(place.id),
                                    onFavoriteTap: () => _toggleFavorite(place),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetailScreen(
                                          placeId: place.id,
                                          username: widget.username,
                                        ),
                                      ),
                                    ).then((_) => _loadData()), // Reload favorites
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: Color(0xFFBDC3C7)),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7F8C8D))),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A3E4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Color(0xFFBDC3C7)),
          SizedBox(height: 16),
          Text('Destinasi yang kamu cari belum ada nih',
              style: TextStyle(color: Color(0xFF7F8C8D))),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar Akun', style: TextStyle(color: Color(0xFF1C2833), fontWeight: FontWeight.bold)),
        content: const Text('Kamu yakin ingin keluar dari akun ini?',
            style: TextStyle(color: Color(0xFF7F8C8D))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF7F8C8D), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}