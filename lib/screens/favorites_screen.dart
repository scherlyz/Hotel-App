import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/place.dart';
import '../services/api_service.dart';
import '../widgets/place_card.dart';
import 'detail_screen.dart';
import 'login_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final String username;
  final bool isGuest;

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  const FavoritesScreen({
    super.key,
    required this.username,
    this.isGuest = false,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with RouteAware, WidgetsBindingObserver {
  List<Place> _favorites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!widget.isGuest) _loadFavorites();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      FavoritesScreen.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FavoritesScreen.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (!widget.isGuest) _loadFavorites();
  }

  @override
  void didPush() {
    if (!widget.isGuest) _loadFavorites();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !widget.isGuest) {
      _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final result = await ApiService.getFavorites(widget.username);
      if (!mounted) return;
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
      if (!mounted) return;
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
      if (!mounted) return;
      if (result['favorited'] == false || result['status'] == 'ok') {
        setState(() => _favorites.removeWhere((p) => p.id == place.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${place.name} dihapus dari favorit'),
            backgroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Batalkan',
              textColor: AppColors.background,
              onPressed: _loadFavorites,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus favorit: $e'),
          backgroundColor: AppColors.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Favorit Saya',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (!widget.isGuest)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              onPressed: _loadFavorites,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // ─── Guest: prompt login ───────────────────────
    if (widget.isGuest) return _buildGuestPrompt();

    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFavorites,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Coba Lagi',
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

    if (_favorites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline_rounded,
                size: 72, color: AppColors.textMuted),
            SizedBox(height: 20),
            Text('Belum ada favorit nih',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            SizedBox(height: 8),
            Text(
              'Cari destinasi impianmu\ndan simpan ke sini!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textMuted, height: 1.5, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: AppColors.primary,
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
                color: AppColors.error,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white, size: 32),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Text('Hapus Favorit?',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold)),
                  content: Text(
                      'Yakin ingin menghapus ${place.name} dari daftar favoritmu?',
                      style: const TextStyle(color: AppColors.textSecondary)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal',
                          style: TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.error),
                      child: const Text('Hapus',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                        isGuest: false,
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

  // ─── Guest prompt ─────────────────────────────────────────────────────────
  Widget _buildGuestPrompt() {
    return Center(
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
              child: const Icon(Icons.favorite_outline_rounded,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text('Simpan Favoritmu',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            const Text(
              'Login untuk menyimpan tempat favorit\ndan mengaksesnya kapan saja.',
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
                child: const Text('Login / Daftar',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}