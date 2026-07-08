import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import '../models/place.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import 'detail_screen.dart';
import 'login_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final String username;
  final bool isGuest;
  final FavoritesService? favoritesService;
  final VoidCallback? onBackToHome;

  const FavoritesScreen({
    super.key,
    required this.username,
    this.isGuest = false,
    this.favoritesService,
    this.onBackToHome,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  // 0 = default, 1 = rating tertinggi, 2 = nama A-Z
  int _sortMode = 0;

  List<Place> get _favorites => widget.favoritesService?.favorites ?? [];

  bool get _showInitialLoading =>
      !widget.isGuest &&
      widget.favoritesService != null &&
      !widget.favoritesService!.isLoaded &&
      widget.favoritesService!.isFetching;

  List<Place> get _displayedFavorites {
    var list = _favorites.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.address.toLowerCase().contains(q);
    }).toList();

    if (_sortMode == 1) {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortMode == 2) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    widget.favoritesService?.addListener(_onFavoritesChanged);
    if (!widget.isGuest && widget.favoritesService != null) {
      if (!widget.favoritesService!.isLoaded) {
        widget.favoritesService!.load();
      }
    }
  }

  @override
  void dispose() {
    widget.favoritesService?.removeListener(_onFavoritesChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

        Future<void> _removeFavorite(Place place) async {

        final service = widget.favoritesService;

        if(service==null) return;

        final success =
            await service.toggle(place);

        if(!mounted) return;

        if(!success){

          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content: const Text(
                "Gagal menghapus favorit",
              ),
              backgroundColor: AppColors.error,
            ),
          );

          return;

        }

        final messenger =
            ScaffoldMessenger.of(context);

        messenger.hideCurrentSnackBar();

        messenger.showSnackBar(

          SnackBar(

            duration:
                const Duration(seconds:3),

            content: Text(
              "${place.name} dihapus dari favorit",
            ),

            action: SnackBarAction(

              label: "Batalkan",

              textColor: Colors.white,

              onPressed: () async {

                await service.toggle(place);

              },

            ),

          ),

        );

      }

  @override
  Widget build(BuildContext context) {
       final bottomSafe = MediaQuery.of(context).padding.bottom;
    const navBarClearance = 70.0;

    final screenHeight = MediaQuery.of(context).size.height;
    final double headerHeight = (screenHeight * 0.28).clamp(180.0, 270.0);
    final double initialSheetSize =
        (1 - (headerHeight - 28) / screenHeight).clamp(0.72, 0.9);
    final double safeTopGap = MediaQuery.of(context).padding.top + 76;
    final double maxSheetSize =
        (1 - safeTopGap / screenHeight).clamp(initialSheetSize, 0.95);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ─── Header foto — fixed di belakang (tidak ikut scroll) ─────
          SizedBox(
            height: headerHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'lib/assets/images/hero_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, __) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, Color(0xFF0F2E28)],
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: .45),
                        Colors.black.withValues(alpha: .15),
                        Colors.black.withValues(alpha: .55),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Form: bisa ditarik naik, berisi search, filter & daftar favorit ──
          DraggableScrollableSheet(
            initialChildSize: initialSheetSize,
            minChildSize: initialSheetSize,
            maxChildSize: maxSheetSize,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Search | Filter ─────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 46,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(Icons.search_rounded,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                    Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            inputDecorationTheme: const InputDecorationTheme(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                            ),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                            cursorColor: AppColors.primary,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search places or hotels...',
                              hintStyle: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 14,
                              ),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _circleHeaderButton(
                            icon: Icons.tune_rounded,
                            onTap: _showSortSheet,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ─── Label "Favorite" ─────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Favorite',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                            ),
                          ),
                          if (!widget.isGuest)
                            Text('${_favorites.length} tempat',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    Expanded(child: _buildBody(scrollController)),
                  ],
                ),
              );
            },
          ),

          // ─── Back button — fixed di atas foto ─────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 20,
            child: _circleHeaderButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () {
                if (widget.onBackToHome != null) {
                  widget.onBackToHome!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ScrollController controller) {
    // ─── Guest: prompt login ───────────────────────
    if (widget.isGuest) {
      return ListView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [_buildGuestPrompt()],
      );
    }

    if (_showInitialLoading) {
      return ListView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.12),
          const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      );
    }

    if (_favorites.isEmpty && widget.favoritesService?.isLoaded == true) {
      return ListView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_outline_rounded,
                    size: 72, color: AppColors.primary.withValues(alpha: 0.4)),
                const SizedBox(height: 20),
                const Text('Belum ada favorit nih',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text(
                  'Cari destinasi impianmu\ndan simpan ke sini!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textMuted, height: 1.5, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final displayed = _displayedFavorites;

    if (displayed.isEmpty) {
      // Favorit ada, tapi pencarian tidak menemukan hasil
      return ListView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded,
                    size: 64, color: AppColors.textMuted),
                SizedBox(height: 16),
                Text('Tidak ditemukan',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                SizedBox(height: 6),
                Text('Coba kata kunci lain',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: displayed.length,
      itemBuilder: (context, index) {
        final place = displayed[index];
        return Dismissible(
          key: Key(place.id.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 28),
            margin: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 32),
          ),
      confirmDismiss: (_) async {

        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("Hapus Favorit?"),
            content: Text(
              "Yakin ingin menghapus ${place.name} dari favorit?",
            ),
            actions: [

              TextButton(
                onPressed: (){
                  Navigator.pop(ctx,false);
                },
                child: const Text("Batal"),
              ),

              TextButton(
                onPressed: (){
                  Navigator.pop(ctx,true);
                },
                child: const Text("Hapus"),
              ),

            ],
          ),
        );

        if(confirm==true){

            await _removeFavorite(place);

        }

        // Dismissible jangan menghapus widget sendiri
        return false;
      },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                  child: _favoriteListItem(place),
                ),
              );
            },
          );
        }

  // ─── Kartu favorit horizontal, layout sesuai referensi ─────────────────
  Widget _favoriteListItem(Place place) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(
              placeId: place.id,
              username: widget.username,
              isGuest: false,
              favoritesService: widget.favoritesService,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7EE), // hijau muda
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 72,
                height: 72,
                child: place.photoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ApiService.resolveImageUrl(place.photoUrl),
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey.shade200),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.hotel,
                              color: AppColors.textHint),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child:
                            const Icon(Icons.hotel, color: AppColors.textHint),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(place.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.gold, size: 15),
                      const SizedBox(width: 3),
                      Text(
                        place.rating > 0
                            ? place.rating.toStringAsFixed(1)
                            : 'New',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  // Harga — sekarang di bawah rating
                  if (place.priceRange.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(place.priceRange,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Icon love dengan lingkaran (pengganti bookmark)
            GestureDetector(
              onTap: () => _removeFavorite(place),
              child: Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(top: 2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: AppColors.error, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tombol bulat untuk back & filter ──────────────────────────────────
  Widget _circleHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }

  // ─── Bottom sheet filter/sort ───────────────────────────────────────────
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        Widget option(String label, int mode) {
          final selected = _sortMode == mode;
          return ListTile(
            title: Text(label,
                style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textPrimary)),
            trailing: selected
                ? const Icon(Icons.check_rounded, color: AppColors.primary)
                : null,
            onTap: () {
              setState(() => _sortMode = mode);
              Navigator.pop(ctx);
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Urutkan',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
              ),
              option('Default', 0),
              option('Rating Tertinggi', 1),
              option('Nama A-Z', 2),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
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