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
              backgroundColor: const Color(0xFF1C2833),
              action: SnackBarAction(
                label: 'Batalkan',
                textColor: const Color(0xFFFFC107),
                onPressed: _loadFavorites,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus favorit: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Favorit Saya', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00A3E4),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadFavorites,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00A3E4)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: Color(0xFFE74C3C)),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF7F8C8D))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFavorites,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A3E4), foregroundColor: Colors.white),
              child: const Text('Coba Lagi'),
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
            const Icon(Icons.favorite_outline_rounded, size: 72, color: Color(0xFFBDC3C7)),
            const SizedBox(height: 20),
            const Text(
              'Belum ada favorit nih',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C2833)),
            ),
            const SizedBox(height: 8),
            Text(
              'Cari destinasi impianmu\ndan simpan ke sini!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], height: 1.5),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: const Color(0xFF00A3E4),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final place = _favorites[index];
          return Dismissible(
            key: Key(place.id.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 28),
              margin: const EdgeInsets.only(bottom: 12, right: 16, left: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4B4B), // Red
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 32),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Hapus Favorit?', style: TextStyle(color: Color(0xFF1C2833), fontWeight: FontWeight.bold)),
                  content: Text('Yakin ingin menghapus ${place.name} dari daftar favoritmu?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal', style: TextStyle(color: Color(0xFF7F8C8D), fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF4B4B)),
                      child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (_) => _removeFavorite(place),
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
          );
        },
      ),
    );
  }
}