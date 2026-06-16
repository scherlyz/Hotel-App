import 'package:flutter/material.dart';
import '../models/place.dart';
import '../services/api_service.dart';
import '../widgets/place_card.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final bool isAdmin;
  final double? userLat;
  final double? userLng;

  const HomeScreen({
    super.key,
    required this.username,
    this.isAdmin = false,
    this.userLat,
    this.userLng,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Place> _allPlaces = [];
  List<Place> _filteredPlaces = [];
  final List<String> _filters = ['Semua', 'Hotel Terdekat', 'Harga Termurah'];
  String _selectedFilter = 'Semua';
  Set<int> _favoriteIds = {};
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

    try {
      final placesResult = await ApiService.getAllPlaces();
      if (!mounted) return;
      if (placesResult['status'] == 'ok') {
        final List data = placesResult['data'] ?? [];
        _allPlaces = data.map((e) => Place.fromJson(e)).toList();
        _filteredPlaces = List.from(_allPlaces);
      } else {
        _error = placesResult['message'] ?? 'Gagal memuat data';
      }

      final favResult = await ApiService.getFavorites(widget.username);
      if (!mounted) return;
      if (favResult['status'] == 'ok') {
        final List favs = favResult['data'] ?? [];
        _favoriteIds = favs.map<int>((e) => int.tryParse(e['id'].toString()) ?? 0).toSet();
      }

      _filterPlaces();
    } catch (e) {
      _error = 'Gagal memuat data: $e';
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // Hanya reload favorites (lebih ringan, tidak perlu reload semua places)
  Future<void> _reloadFavorites() async {
    try {
      final favResult = await ApiService.getFavorites(widget.username);
      if (!mounted) return;
      if (favResult['status'] == 'ok') {
        final List favs = favResult['data'] ?? [];
        setState(() {
          _favoriteIds = favs
              .map<int>((e) => int.tryParse(e['id'].toString()) ?? 0)
              .toSet();
        });
      }
    } catch (_) {}
  }

  // Haversine distance (km)
  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * 3.14159265358979 / 180;
    final dLng = (lng2 - lng1) * 3.14159265358979 / 180;
    final a = (dLat / 2) * (dLat / 2) +
        ((lat1 * 3.14159265358979 / 180).abs() *
            (lat2 * 3.14159265358979 / 180).abs() *
            (dLng / 2) *
            (dLng / 2));
    final c = 2 * (a < 1 ? a : 1);
    return r * c;
  }

  void _filterPlaces() {
    final query = _searchCtrl.text.toLowerCase();

    setState(() {
      // Filter teks
      _filteredPlaces = _allPlaces.where((p) {
        return query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            p.address.toLowerCase().contains(query);
      }).toList();

      // Sorting
      if (_selectedFilter == 'Harga Termurah') {
        _filteredPlaces.sort((a, b) => a.priceMin.compareTo(b.priceMin));
      } else if (_selectedFilter == 'Hotel Terdekat') {
        if (widget.userLat != null && widget.userLng != null) {
          _filteredPlaces.sort((a, b) {
            final distA = _distanceKm(a.lat, a.lng, widget.userLat!, widget.userLng!);
            final distB = _distanceKm(b.lat, b.lng, widget.userLat!, widget.userLng!);
            return distA.compareTo(distB);
          });
        }
      }
    });
  }

  Future<void> _toggleFavorite(Place place) async {
    print('Toggling favorite for place id: ${place.id}, username: ${widget.username}');
    final result = await ApiService.toggleFavorite(place.id, widget.username);
    print('toggleFavorite result: $result');
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
    return Container(
      color: const Color(0xFFF5F5DC),
      child: Column(
        children: [
          // ─── Search Bar ────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _filterPlaces(),
              style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
              decoration: const InputDecoration(
                hintText: 'Cari tempat wisata atau hotel...',
                hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF2D8B6F), size: 22),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),

          // ─── Filter Pills ──────────────────────────────
          SizedBox(
            height: 64,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final filterName = _filters[i];
                final selected = filterName == _selectedFilter;
                // Disable "Hotel Terdekat" kalau lokasi tidak tersedia
                final isDisabled = filterName == 'Hotel Terdekat' &&
                    widget.userLat == null;
                return GestureDetector(
                  onTap: isDisabled
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Izinkan akses lokasi untuk menggunakan filter ini'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : () {
                          setState(() => _selectedFilter = filterName);
                          _filterPlaces();
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? const Color(0xFFF5F5F5)
                          : selected
                              ? const Color(0xFF2D8B6F)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDisabled
                            ? const Color(0xFFE8E8E8)
                            : selected
                                ? const Color(0xFF2D8B6F)
                                : const Color(0xFFE8E8E8),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (filterName == 'Hotel Terdekat') ...[
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: isDisabled
                                ? const Color(0xFFCCCCCC)
                                : selected
                                    ? Colors.white
                                    : const Color(0xFF555555),
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (filterName == 'Harga Termurah') ...[
                          Icon(
                            Icons.attach_money_rounded,
                            size: 14,
                            color: selected ? Colors.white : const Color(0xFF555555),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          filterName,
                          style: TextStyle(
                            color: isDisabled
                                ? const Color(0xFFCCCCCC)
                                : selected
                                    ? Colors.white
                                    : const Color(0xFF555555),
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ─── Jumlah hasil ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filteredPlaces.length} tempat ditemukan',
                  style: const TextStyle(
                      color: Color(0xFF8899A6), fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (_selectedFilter != 'Semua') ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedFilter = 'Semua');
                      _filterPlaces();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D8B6F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _selectedFilter,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2D8B6F),
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.close, size: 11, color: Color(0xFF2D8B6F)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ─── List Tempat ───────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D8B6F)))
                : _error != null
                    ? _buildError()
                    : _filteredPlaces.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: const Color(0xFF2D8B6F),
                            backgroundColor: Colors.white,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                              itemCount: _filteredPlaces.length,
                              itemBuilder: (_, i) {
                                final place = _filteredPlaces[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: PlaceCard(
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
                                    ).then((_) => _reloadFavorites()), // ✅ reload favorites setelah balik
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: Color(0xFF8899A6)),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8899A6), fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Coba lagi', style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D8B6F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
          Icon(Icons.search_off, size: 56, color: Color(0xFF8899A6)),
          SizedBox(height: 16),
          Text('Tidak ada tempat yang ditemukan',
              style: TextStyle(color: Color(0xFF8899A6), fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}