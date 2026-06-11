import 'package:flutter/material.dart';
import '../models/place.dart';
import '../services/api_service.dart';
import '../widgets/place_card.dart';
import 'detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final String username;

  const FavoritesScreen({super.key, required this.username});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Place> _favorites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.getFavorites(widget.username);

      if (result['status'] == 'ok') {
        final List data = result['data'] ?? [];
        setState(() {
          _favorites = data.map((e) => Place.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Gagal memuat favorit';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(Place place) async {
    try {
      final result = await ApiService.postRequest('toggle_favorite', {
        'place_id': place.id,
        'username': widget.username,
      });

      if (result['favorited'] == false) {
        setState(() {
          _favorites.removeWhere((p) => p.id == place.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${place.name} dihapus dari favorit'),
              backgroundColor: const Color(0xFF1A1A1A), // Dark mode style snackbar
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Batalkan',
                textColor: const Color(0xFFF5F5DC), // Cream text for action
                onPressed: _loadFavorites,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus favorit: $e'),
            backgroundColor: const Color(0xFFDC2626), // Soft Red
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Cream beige background
      appBar: AppBar(
        title: const Text('Favorit Saya', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: const Color(0xFFF5F5DC),
        foregroundColor: const Color(0xFF1A1A1A), // Dark text
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2D8B6F)), // Deep green icon
            onPressed: _loadFavorites,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2D8B6F)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: Color(0xFF8899A6)),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8899A6))),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFavorites,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w600)),
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

    if (_favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_outline_rounded, size: 72, color: Color(0xFF8899A6)),
            const SizedBox(height: 20),
            const Text(
              'Belum ada favorit nih',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cari destinasi impianmu\ndan simpan ke sini!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8899A6), height: 1.5, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: const Color(0xFF2D8B6F),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final place = _favorites[index];
          return Dismissible(
            key: Key(place.id.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 28),
              margin: const EdgeInsets.only(bottom: 16, right: 24, left: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626), // Soft Red
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 32),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Hapus Favorit?', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold)),
                  content: Text('Yakin ingin menghapus ${place.name} dari daftar favoritmu?', style: const TextStyle(color: Color(0xFF555555))),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal', style: TextStyle(color: Color(0xFF8899A6), fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                      child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (_) => _removeFavorite(place),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
              child: PlaceCard(
                place: place,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(
                        placeId: place.id,
                        username: widget.username,
                      ),
                    ),
                  ).then((_) => _loadFavorites());
                },
                onFavoriteTap: () => _removeFavorite(place),
                isFavorite: true,
              ),
            ),
          );
        },
      ),
    );
  }
}