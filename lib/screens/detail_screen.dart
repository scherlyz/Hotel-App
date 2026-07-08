import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'map_screen.dart';
import '../widgets/place_card.dart'; 
import 'login_screen.dart';
import '../models/place.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../core/constants/app_colors.dart';

class DetailScreen extends StatefulWidget {
  final int placeId;
  final String username;
  final bool isGuest;
  final FavoritesService? favoritesService;

  const DetailScreen({
    super.key,
    required this.placeId,
    required this.username,
    this.isGuest = false,
    this.favoritesService,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _selectedTab = 0; // 0 = About, 1 = Review
  Place? _place;
  List<Review> _reviews = [];
  bool _isLoading = true;
  bool _isSubmittingReview = false;
  String? _error;

  final _commentCtrl = TextEditingController();
  double _myRating = 5.0;
  bool _descExpanded = false;
  List<Place> _recommended = [];

  @override
  void initState() {
    super.initState();
    widget.favoritesService?.addListener(_onFavoritesChanged);
    _loadDetail();
  }

  @override
  void dispose() {
    widget.favoritesService?.removeListener(_onFavoritesChanged);
    _commentCtrl.dispose();
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  bool get _isFavorite =>
      !widget.isGuest &&
      (widget.favoritesService?.isFavorite(widget.placeId) ?? false);

  Future<void> _loadDetail() async {
    setState(() { _isLoading = true; _error = null; });

    final futures = <Future>[
      ApiService.getPlaceById(widget.placeId),
      ApiService.getReviews(widget.placeId),
      // Hanya fetch favorites kalau bukan guest
      if (!widget.isGuest) ApiService.getFavorites(widget.username),
    ];

    final results = await Future.wait(futures);
    if (!mounted) return;

    if (results[0]['status'] == 'ok') {
      _place = Place.fromJson(results[0]['data']);
    } else {
      _error = results[0]['message'] ?? 'Gagal memuat detail';
    }

    if (results[1]['status'] == 'ok') {
      final List data = results[1]['data'] ?? [];
      _reviews = data.map((e) => Review.fromJson(e)).toList();
    }

    setState(() => _isLoading = false);

    // Ambil rekomendasi hotel serupa (kategori sama), tidak blocking loading utama
    if (_place != null) {
      _loadRecommended(_place!.category);
    }
  }

  // ─── Rekomendasi hotel serupa (kategori sama, exclude hotel ini sendiri) ───
  Future<void> _loadRecommended(String category) async {
    if (category.isEmpty) return;
    try {
      final result = await ApiService.getPlacesByCategory(category);
      if (!mounted) return;
      if (result['status'] == 'ok') {
        final List data = result['data'] ?? [];
        final list = data
            .map((e) => Place.fromJson(e))
            .where((p) => p.id != widget.placeId)
            .take(8)
            .toList();
        setState(() => _recommended = list);
      }
    } catch (_) {
      // Diamkan — rekomendasi bersifat pelengkap, bukan data wajib
    }
  }

  // ─── Guard: tampil dialog login kalau guest ────────────────────────────────
  void _requireLogin(VoidCallback action) {
    if (widget.isGuest) {
      _showLoginDialog();
      return;
    }
    action();
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Login Diperlukan',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: const Text(
          'Kamu perlu login untuk menggunakan fitur ini.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
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
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    if (_place == null) return;
    final service = widget.favoritesService;
    if (service == null) return;

    final wasFavorite = _isFavorite;
    final success = await service.toggle(_place!);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite
              ? 'Ditambahkan ke favorit'
              : 'Dihapus dari favorit'),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasFavorite
              ? 'Gagal menghapus dari favorit'
              : 'Gagal menambahkan ke favorit'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _submitReview() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() => _isSubmittingReview = true);

    final result = await ApiService.addReview(
      widget.placeId,
      widget.username,
      _myRating,
      _commentCtrl.text.trim(),
    );

    setState(() => _isSubmittingReview = false);
    if (!mounted) return;

    if (result['status'] == 'ok') {
      _commentCtrl.clear();
      Navigator.pop(context);
      _loadDetail();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Review berhasil dikirim!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tulis Review',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Rating: ',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontSize: 15)),
                  ...List.generate(5, (i) {
                    final starVal = (i + 1).toDouble();
                    return GestureDetector(
                      onTap: () => setSheetState(() => _myRating = starVal),
                      child: Icon(
                        _myRating >= starVal
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFFFC107),
                        size: 36,
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentCtrl,
                maxLines: 4,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ceritakan pengalamanmu...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmittingReview ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmittingReview
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Kirim Review',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_error != null || _place == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0),
        body: Center(
          child: Text(_error ?? 'Data tidak ditemukan',
              style: const TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    final place = _place!;
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
          SizedBox(
            height: headerHeight,
            width: double.infinity,
            child: place.photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: ApiService.resolveImageUrl(place.photoUrl),
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: Colors.grey, size: 40),
                    ),
                  )
                : Container(
                    color: AppColors.primary,
                    child: const Icon(Icons.image_outlined,
                        size: 64, color: Colors.white54),
                  ),
          ),

          // ─── Form detail hotel — bisa ditarik naik sampai penuh 1 layar ────
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
                // scrollController dari DraggableScrollableSheet dipasang di
                // sini: drag ke atas akan membesarkan sheet dulu, baru
                // setelah full ukurannya konten di dalam ikut discroll.
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 8),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(place.name,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    height: 1.2)),
                          ),
                          if (place.priceRange.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(place.priceRange,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tab selector manual: About & Review (bukan TabBar/TabBarView
                    // supaya tidak butuh tinggi pasti dan tidak bisa overflow)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          _tabButton('About', 0),
                          const SizedBox(width: 24),
                          _tabButton('Review', 1),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 4),

                    if (_selectedTab == 0)
                      _buildAboutTab(place)
                    else
                      _buildReviewTab(place),
                  ],
                ),
              );
            },
          ),

          // ─── Back button — fixed di atas gambar ─────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 20,
            child: _circleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),

          // ─── Favorite button — fixed di atas gambar ─────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: _circleIconButton(
              icon: widget.isGuest
                  ? Icons.favorite_border_rounded
                  : (_isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded),
              iconColor: (!widget.isGuest && _isFavorite)
                  ? AppColors.error
                  : Colors.white,
              onTap: () => _requireLogin(_toggleFavorite),
            ),
          ),

          // ─── Tombol "Direct" — floating, oval, tanpa icon ─────────────────
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () => _requireLogin(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MapScreen(place: place)),
                  );
                }),
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.isGuest ? 'Login untuk Lanjut' : 'Direct',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab: About ─────────────────────────────────────────────────────────
  Widget _buildAboutTab(Place place) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Quick facts (data asli, tanpa tag "Hotel")
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (place.stars > 0)
              _factChip(Icons.star_rounded, '${place.stars}★'),
            if (place.workingHours.isNotEmpty)
              _factChip(Icons.access_time_rounded, place.workingHours),
          ],
        ),
        if (place.stars > 0 || place.workingHours.isNotEmpty)
          const SizedBox(height: 20),

        if (place.phone.isNotEmpty)
          _infoTile(Icons.phone_outlined, place.phone),
        if (place.website.isNotEmpty)
          _infoTile(Icons.language_rounded, place.website),

        // Deskripsi dengan Read more/less
        if (place.description.isNotEmpty) ...[
          const Text('Description',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Text(
            place.description,
            maxLines: _descExpanded ? null : 2,
            overflow: _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppColors.textSecondary, height: 1.6, fontSize: 14),
          ),
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _descExpanded ? 'Tampilkan lebih sedikit' : 'Read more',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],

        // Lokasi — tampilkan peta, bukan teks alamat
        if (place.lat != 0 && place.lng != 0) ...[
          const Text('Location',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _mapPreviewCard(place),
          const SizedBox(height: 12),
        ],

        // Rekomendasi hotel serupa (kategori sama)
        if (_recommended.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Rekomendasi Hotel',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recommended.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final rec = _recommended[index];
                return SizedBox(
                  width: 200,
                  child: PlaceCard(
                    place: rec,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(
                            placeId: rec.id,
                            username: widget.username,
                            isGuest: widget.isGuest,
                            favoritesService: widget.favoritesService,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
        ],
      ),
    );
  }

  // ─── Tab: Review ────────────────────────────────────────────────────────
  Widget _buildReviewTab(Place place) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 20),
            const SizedBox(width: 6),
            Text(place.rating.toStringAsFixed(1),
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 15)),
            const SizedBox(width: 6),
            Text('(${_reviews.length} ulasan)',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        _ratingBar('Rating keseluruhan', place.rating),
        const SizedBox(height: 24),

        Row(
          children: [
            const Text('Ulasan',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const Spacer(),
            SizedBox(
              height: 34,
              child: OutlinedButton.icon(
                onPressed: () => _requireLogin(_showReviewSheet),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: Icon(
                  widget.isGuest
                      ? Icons.lock_outline_rounded
                      : Icons.rate_review_outlined,
                  color: AppColors.primary,
                  size: 15,
                ),
                label: Text(
                  widget.isGuest ? 'Login' : 'Tulis Review',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_reviews.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  const Icon(Icons.forum_outlined,
                      size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('Belum ada ulasan.',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    widget.isGuest
                        ? 'Login untuk menulis ulasan pertama!'
                        : 'Jadilah yang pertama me-review!',
                    style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.8),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          ..._reviews.map((r) => _reviewTile(r)),
        ],
      ),
    );
  }

  Widget _mapPreviewCard(Place place) {
    final latLng = LatLng(place.lat, place.lng);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 150,
        child: AbsorbPointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: latLng,
              initialZoom: 14,
              interactionOptions:
                  const InteractionOptions(flags: InteractiveFlag.none),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_hotel',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: latLng,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on_rounded,
                        color: AppColors.error, size: 36),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 28,
              height: 2.5,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _factChip(IconData icon, String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _ratingBar(String label, double value) {
    final pct = (value / 5.0).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(value.toStringAsFixed(1),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _infoTile(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _reviewTile(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.background,
                child: Text(
                  review.username.isNotEmpty
                      ? review.username[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(review.username,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
              Row(
                children: List.generate(
                  review.rating.round().clamp(0, 5),
                  (_) => const Icon(Icons.star_rounded,
                      size: 16, color: Color(0xFFFFC107)),
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(review.comment,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4)),
          ],
        ],
      ),
    );
  }
}