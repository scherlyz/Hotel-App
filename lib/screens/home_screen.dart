import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/place.dart';
import '../services/api_service.dart';
import '../widgets/place_card.dart';
import 'detail_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final bool isAdmin;
  final bool isGuest;
  final double? userLat;
  final double? userLng;

  const HomeScreen({
    super.key,
    required this.username,
    this.isAdmin = false,
    this.isGuest = false,
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

      // Hanya fetch favorites kalau bukan guest
      if (!widget.isGuest) {
        final favResult = await ApiService.getFavorites(widget.username);
        if (!mounted) return;
        if (favResult['status'] == 'ok') {
          final List favs = favResult['data'] ?? [];
          _favoriteIds = favs
              .map<int>((e) => int.tryParse(e['id'].toString()) ?? 0)
              .toSet();
        }
      }

      _filterPlaces();
    } catch (e) {
      _error = 'Gagal memuat data: $e';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _reloadFavorites() async {
    if (widget.isGuest) return;
    try {
      final favResult = await ApiService.getFavorites(widget.username);
      if (!mounted) return;
      if (favResult['status'] == 'ok') {
        final List favs = favResult['data'] ?? [];
        setState(() {
          _favoriteIds =
              favs.map<int>((e) => int.tryParse(e['id'].toString()) ?? 0).toSet();
        });
      }
    } catch (_) {}
  }

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
      _filteredPlaces = _allPlaces.where((p) {
        return query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            p.address.toLowerCase().contains(query);
      }).toList();

      if (_selectedFilter == 'Harga Termurah') {
        _filteredPlaces.sort((a, b) => a.priceMin.compareTo(b.priceMin));
      } else if (_selectedFilter == 'Hotel Terdekat') {
        if (widget.userLat != null && widget.userLng != null) {
          _filteredPlaces.sort((a, b) {
            final dA = _distanceKm(a.lat, a.lng, widget.userLat!, widget.userLng!);
            final dB = _distanceKm(b.lat, b.lng, widget.userLat!, widget.userLng!);
            return dA.compareTo(dB);
          });
        }
      }
    });
  }

  Future<void> _toggleFavorite(Place place) async {
    // Guest → arahkan ke login
    if (widget.isGuest) {
      _showLoginPrompt();
      return;
    }
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

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Login Diperlukan',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: const Text('Login untuk menyimpan favorit dan mengakses fitur lengkap.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti',
                style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // ─── Search Bar ──────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _filterPlaces(),
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Cari tempat wisata atau hotel...',
                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                prefixIcon:
                    Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),

          // ─── Filter Pills ────────────────────────────
          SizedBox(
            height: 64,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final name = _filters[i];
                final selected = name == _selectedFilter;
                final isDisabled =
                    name == 'Hotel Terdekat' && widget.userLat == null;
                return GestureDetector(
                  onTap: isDisabled
                      ? () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Izinkan akses lokasi untuk menggunakan filter ini'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          )
                      : () {
                          setState(() => _selectedFilter = name);
                          _filterPlaces();
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? const Color(0xFFF5F5F5)
                          : selected
                              ? AppColors.primary
                              : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDisabled
                            ? AppColors.border
                            : selected
                                ? AppColors.primary
                                : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (name == 'Hotel Terdekat') ...[
                          Icon(Icons.location_on_rounded,
                              size: 14,
                              color: isDisabled
                                  ? const Color(0xFFCCCCCC)
                                  : selected
                                      ? Colors.white
                                      : AppColors.textSecondary),
                          const SizedBox(width: 4),
                        ],
                        if (name == 'Harga Termurah') ...[
                          Icon(Icons.attach_money_rounded,
                              size: 14,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          name,
                          style: TextStyle(
                            color: isDisabled
                                ? const Color(0xFFCCCCCC)
                                : selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
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

          // ─── Jumlah hasil ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filteredPlaces.length} tempat ditemukan',
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                if (_selectedFilter != 'Semua') ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedFilter = 'Semua');
                      _filterPlaces();
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(_selectedFilter,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 3),
                          const Icon(Icons.close,
                              size: 11, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ─── List Tempat ─────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : _filteredPlaces.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: AppColors.primary,
                            backgroundColor: Colors.white,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 8, 24, 24),
                              itemCount: _filteredPlaces.length,
                              itemBuilder: (_, i) {
                                final place = _filteredPlaces[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: PlaceCard(
                                    place: place,
                                    isFavorite: !widget.isGuest &&
                                        _favoriteIds.contains(place.id),
                                    onFavoriteTap: () =>
                                        _toggleFavorite(place),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetailScreen(
                                          placeId: place.id,
                                          username: widget.username,
                                          isGuest: widget.isGuest,
                                        ),
                                      ),
                                    ).then((_) => _reloadFavorites()),
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
          const Icon(Icons.wifi_off, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Coba lagi',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          Icon(Icons.search_off, size: 56, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text('Tidak ada tempat yang ditemukan',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}