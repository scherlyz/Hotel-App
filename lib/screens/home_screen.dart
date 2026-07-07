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
  final String locationText;
  final bool locationLoading;

  const HomeScreen({
    super.key,
    required this.username,
    this.isAdmin = false,
    this.isGuest = false,
    this.userLat,
    this.userLng,
    this.locationText = 'Getting location...',
    this.locationLoading = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _heroImageUrl = 'lib/assets/images/hero_bg.png';

  List<Place> _allPlaces = [];
  List<Place> _filteredPlaces = [];
  final List<String> _filters = ['All', 'Nearby', 'Cheapest'];
  String _selectedFilter = 'All';
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
        _error = placesResult['message'] ?? 'Failed to load data';
      }

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
      _error = 'Failed to load data: $e';
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

      if (_selectedFilter == 'Cheapest') {
        _filteredPlaces.sort((a, b) => a.priceMin.compareTo(b.priceMin));
      } else if (_selectedFilter == 'Nearby') {
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
    if (widget.isGuest) {
      _showLoginPrompt();
      return;
    }
    final result = await ApiService.toggleFavorite(place.id, widget.username);
    debugPrint('toggleFavorite result: $result'); // sementara, buat cek respons asli backend

    final bool success =
        result['status'] == 'ok' || result.containsKey('favorited');

    if (success) {
      setState(() {
        if (result['favorited'] == true) {
          _favoriteIds.add(place.id);
        } else {
          _favoriteIds.remove(place.id);
        }
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ??
              'Gagal memperbarui favorit'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Login Required',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: const Text('Login to save favorites and access full features.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later',
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

  List<Place> get _topPlaces {
    final sorted = List<Place>.from(_allPlaces)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(5).toList();
  }

  // ─── Hero header: gambar + overlay + greeting + search bar ────────────
  Widget _buildHeroHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Stack(
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
              top: MediaQuery.of(context).padding.top + 20,
              left: 24,
              right: 24,
              bottom: 106,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .18),
                        border:
                            Border.all(color: Colors.white.withValues(alpha: .4)),
                      ),
                      child: Center(
                        child: Text(
                          widget.username.isNotEmpty
                              ? widget.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Hi, ',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              Flexible(
                                child: Text(
                                  widget.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (widget.isAdmin) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
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
                              if (widget.isGuest) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Guest',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: Colors.white70, size: 13),
                              const SizedBox(width: 4),
                              Expanded(
                                child: widget.locationLoading
                                    ? const Text('Getting location...',
                                        style: TextStyle(
                                            color: Colors.white70, fontSize: 12))
                                    : Text(widget.locationText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Column(
        children: [
          // ─── Header + search bar (search bar menggantung setengah
          // di bawah header, sesuai referensi) ─────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildHeroHeader(),
              Positioned(
                left: 24,
                right: 24,
                bottom: -16, 
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 52,
                        child: Icon(Icons.search_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => _filterPlaces(),
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              height: 1.0),
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Search places or hotels...',
                            hintStyle: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 14,
                                height: 1.0),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Ruang kosong untuk sisa search bar yang menggantung di bawah
          // header, supaya tidak numpuk dengan konten list di bawahnya.
          const SizedBox(height: 16 + 12),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.primary,
                        backgroundColor: Colors.white,
                        child: ListView(
                          padding: const EdgeInsets.only(top: 16, bottom: 24),
                          children: [
                            // ─── Filter Pills (di atas Rekomendasi) ─────
                            SizedBox(
                              height: 48,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24),
                                scrollDirection: Axis.horizontal,
                                itemCount: _filters.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (_, i) {
                                  final name = _filters[i];
                                  final selected = name == _selectedFilter;
                                  final isDisabled = name == 'Nearby' &&
                                      widget.userLat == null;
                                  return GestureDetector(
                                    onTap: isDisabled
                                        ? () => ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Allow location access to use this filter'),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            )
                                        : () {
                                            setState(
                                                () => _selectedFilter = name);
                                            _filterPlaces();
                                          },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDisabled
                                            ? const Color(0xFFF0F0F0)
                                            : selected
                                                ? AppColors.primary
                                                : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(24),
                                        boxShadow: selected
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.primary
                                                      .withValues(alpha: .25),
                                                  blurRadius: 14,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ]
                                            : null,
                                        border: selected
                                            ? null
                                            : Border.all(
                                                color: AppColors.border),
                                      ),
                                      child: Row(
                                        children: [
                                          if (name == 'Nearby') ...[
                                            Icon(Icons.location_on_rounded,
                                                size: 14,
                                                color: isDisabled
                                                    ? const Color(0xFFCCCCCC)
                                                    : selected
                                                        ? Colors.white
                                                        : AppColors
                                                            .textSecondary),
                                            const SizedBox(width: 4),
                                          ],
                                          if (name == 'Cheapest') ...[
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
                                              fontWeight: selected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
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

                            const SizedBox(height: 24),

                            // ─── Section: Recommendation (carousel) ──
                            if (_topPlaces.isNotEmpty) ...[
                              const Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  'Recommended for You',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 230,
                                child: ListView.separated(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 24),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _topPlaces.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 14),
                                  itemBuilder: (_, i) {
                                    final place = _topPlaces[i];
                                    return SizedBox(
                                      width: 210,
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
                              const SizedBox(height: 28),
                            ],

                            // ─── Jumlah hasil ────────────────────────
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  const Text(
                                    'Discover More Places',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_filteredPlaces.length} found',
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  if (_selectedFilter != 'All') ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setState(
                                            () => _selectedFilter = 'All');
                                        _filterPlaces();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(_selectedFilter,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.primary,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            const SizedBox(width: 3),
                                            const Icon(Icons.close,
                                                size: 11,
                                                color: AppColors.primary),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ─── List Lengkap (vertikal) ──────────────
                            _filteredPlaces.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 40),
                                    child: _buildEmpty(),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    child: Column(
                                      children: _filteredPlaces.map((place) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 16),
                                          child: PlaceCard(
                                            place: place,
                                            isFavorite: !widget.isGuest &&
                                                _favoriteIds
                                                    .contains(place.id),
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
                                            ).then(
                                                (_) => _reloadFavorites()),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                          ],
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
            label: const Text('Try Again',
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
          Text('No places found',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}