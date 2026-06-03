import 'package:flutter/material.dart';
import '../models/place.dart';
import '../services/api_service.dart';
import '../widgets/place_card.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final bool isAdmin;

  const HomeScreen({
    super.key,
    required this.username,
    this.isAdmin = false,
  });

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
    setState(() { _isLoading = true; _error = null; });

    final results = await Future.wait([
      ApiService.getAllPlaces(),
      ApiService.getCategories(),
      ApiService.getFavorites(widget.username),
    ]);

    if (!mounted) return;

    final placesResult = results[0];
    final catResult = results[1];
    final favResult = results[2];

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
        final matchCat = _selectedCategory == 'Semua' || p.category == _selectedCategory;
        final matchQuery = query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            p.address.toLowerCase().contains(query);
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
    return Column(
      children: [
        // ─── Search Bar ────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => _filterPlaces(),
            decoration: const InputDecoration(
              hintText: 'Cari hotel atau tempat wisata...',
              prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF00A3E4)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        // ─── Filter Kategori ───────────────────────────
        SizedBox(
          height: 52,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF00A3E4) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF1C2833),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ─── Jumlah hasil ──────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Text(
                '${_filteredPlaces.length} tempat ditemukan',
                style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 12),
              ),
            ],
          ),
        ),

        // ─── List Tempat ───────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A3E4)))
              : _error != null
                  ? _buildError()
                  : _filteredPlaces.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: const Color(0xFF00A3E4),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 4, bottom: 20),
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
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: Color(0xFF7F8C8D)),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7F8C8D))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
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
          Icon(Icons.search_off, size: 48, color: Color(0xFF7F8C8D)),
          SizedBox(height: 12),
          Text('Tidak ada tempat ditemukan',
              style: TextStyle(color: Color(0xFF7F8C8D))),
        ],
      ),
    );
  }
}