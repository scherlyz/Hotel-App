import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'map_screen.dart';
import 'login_screen.dart';
import '../models/place.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import '../core/constants/app_colors.dart';

class DetailScreen extends StatefulWidget {
  final int placeId;
  final String username;
  final bool isGuest;

  const DetailScreen({
    super.key,
    required this.placeId,
    required this.username,
    this.isGuest = false,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Place? _place;
  List<Review> _reviews = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isSubmittingReview = false;
  String? _error;

  final _commentCtrl = TextEditingController();
  double _myRating = 5.0;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

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

    if (!widget.isGuest && results.length > 2 && results[2]['status'] == 'ok') {
      final List favs = results[2]['data'] ?? [];
      _isFavorite = favs.any((e) => e['id'].toString() == widget.placeId.toString());
    }

    setState(() => _isLoading = false);
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
    final result = await ApiService.toggleFavorite(widget.placeId, widget.username);
    if (!mounted) return;
    if (result['status'] == 'ok') {
      setState(() => _isFavorite = result['favorited'] == true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit'),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
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
          backgroundColor: AppColors.background,
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_error != null || _place == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            elevation: 0),
        body: Center(
          child: Text(_error ?? 'Data tidak ditemukan',
              style: const TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    final place = _place!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── App Bar dengan foto ─────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  // Guard: guest → dialog login
                  onPressed: () => _requireLogin(_toggleFavorite),
                  icon: Icon(
                    widget.isGuest
                        ? Icons.favorite_border_rounded
                        : (_isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded),
                    color: (!widget.isGuest && _isFavorite)
                        ? AppColors.error
                        : Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  place.photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: place.photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator()),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                                size: 40),
                          ),
                        )
                      : Container(
                          color: AppColors.primary,
                          child: const Icon(Icons.image_outlined,
                              size: 64, color: Colors.white54),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama & rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(place.name,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.2)),
                      ),
                      if (place.rating > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFC107), size: 18),
                              const SizedBox(width: 4),
                              Text(place.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(place.category, AppColors.primary),
                      if (place.stars > 0)
                        _chip('${place.stars}★ Hotel', AppColors.gold),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Info tiles
                  _infoTile(Icons.location_on_outlined, place.address),
                  if (place.workingHours.isNotEmpty)
                    _infoTile(Icons.access_time_rounded, place.workingHours),
                  if (place.phone.isNotEmpty)
                    _infoTile(Icons.phone_outlined, place.phone),
                  if (place.website.isNotEmpty)
                    _infoTile(Icons.language_rounded, place.website),
                  _infoTile(Icons.payments_outlined, place.priceRange),
                  const SizedBox(height: 24),

                  // Deskripsi
                  if (place.description.isNotEmpty) ...[
                    const Text('Tentang Tempat Ini',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Text(place.description,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.6,
                            fontSize: 14)),
                    const SizedBox(height: 28),
                  ],

                  // Lokasi / Peta — guest bisa lihat tapi klik → login dialog
                  if (place.lat != 0 && place.lng != 0) ...[
                    const Text('Lokasi',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _requireLogin(() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => MapScreen(place: place)),
                        );
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.map_outlined,
                                  color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.isGuest
                                        ? 'Login untuk Lihat Peta & Rute'
                                        : 'Lihat Peta & Rute',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lat: ${place.lat}, Lng: ${place.lng}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              widget.isGuest
                                  ? Icons.lock_outline_rounded
                                  : Icons.chevron_right_rounded,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Ulasan
                  Row(
                    children: [
                      const Text('Ulasan',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const Spacer(),
                      Text('${_reviews.length} ulasan',
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
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

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // FAB review — guard login untuk guest
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _requireLogin(_showReviewSheet),
        backgroundColor: AppColors.primary,
        elevation: 0,
        icon: Icon(
          widget.isGuest ? Icons.lock_outline_rounded : Icons.rate_review_outlined,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          widget.isGuest ? 'Login untuk Review' : 'Tulis Review',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
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