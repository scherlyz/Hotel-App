import 'package:flutter/material.dart';
import 'map_screen.dart';
import '../models/place.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DetailScreen extends StatefulWidget {
  final int placeId;
  final String username;

  const DetailScreen({super.key, required this.placeId, required this.username});

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final results = await Future.wait([
      ApiService.getPlaceById(widget.placeId),
      ApiService.getReviews(widget.placeId),
      ApiService.getFavorites(widget.username),
    ]);

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

    if (results[2]['status'] == 'ok') {
      final List favs = results[2]['data'] ?? [];
      _isFavorite =
          favs.any((e) => e['id'].toString() == widget.placeId.toString());
    }

    setState(() => _isLoading = false);
  }

  Future<void> _toggleFavorite() async {
    final result =
        await ApiService.toggleFavorite(widget.placeId, widget.username);
        print('toggleFavorite result: $result');
    if (!mounted) return;
    if (result['status'] == 'ok') {
      setState(() => _isFavorite = result['favorited'] == true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isFavorite ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit'),
          backgroundColor: const Color(0xFF1A1A1A),
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
          backgroundColor: const Color(0xFF2D8B6F),
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
            left: 24,
            right: 24,
            top: 24,
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
                      color: Color(0xFF1A1A1A))),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Rating: ',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555555),
                          fontSize: 15)),
                  ...List.generate(5, (i) {
                    final starVal = (i + 1).toDouble();
                    return GestureDetector(
                      onTap: () =>
                          setSheetState(() => _myRating = starVal),
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
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                decoration: InputDecoration(
                  hintText: 'Ceritakan pengalamanmu...',
                  hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2D8B6F), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmittingReview ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D8B6F),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmittingReview
                      ? const SizedBox(
                          height: 20,
                          width: 20,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          backgroundColor: Color(0xFFF5F5DC),
          body: Center(child: CircularProgressIndicator(color: Color(0xFF2D8B6F))));
    }
    if (_error != null || _place == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5DC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F5DC),
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
        ),
        body: Center(
          child: Text(
            _error ?? 'Data tidak ditemukan',
            style: const TextStyle(color: Color(0xFF8899A6)),
          ),
        ),
      );
    }

    final place = _place!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Cream beige background
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF2D8B6F), // Deep green
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
                  onPressed: _toggleFavorite,
                  icon: Icon(
                    _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isFavorite ? const Color(0xFFDC2626) : Colors.white, // Soft red for fav
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
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF2D8B6F),
                          child: const Icon(Icons.image_outlined,
                              size: 64, color: Colors.white54),
                        ),
                  // Gradient overlay agar text/icon lebih terbaca
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
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5DC), // Background senada
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Header Info ───────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                                height: 1.2),
                          ),
                        ),
                        if (place.rating > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE8E8E8)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Color(0xFFFFC107), size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  place.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A),
                                      fontSize: 14),
                                ),
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
                        _chip(place.category, const Color(0xFF2D8B6F)),
                        if (place.stars > 0)
                          _chip('${place.stars}★ Hotel', const Color(0xFFD4AF37)), // Warm gold
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Info List ─────────────────────────────
                    _infoTile(Icons.location_on_outlined, place.address),
                    if (place.workingHours.isNotEmpty)
                      _infoTile(Icons.access_time_rounded, place.workingHours),
                    if (place.phone.isNotEmpty)
                      _infoTile(Icons.phone_outlined, place.phone),
                    if (place.website.isNotEmpty)
                      _infoTile(Icons.language_rounded, place.website),
                    _infoTile(Icons.payments_outlined, place.priceRange),

                    const SizedBox(height: 24),

                    // ─── Deskripsi ─────────────────────────────
                    if (place.description.isNotEmpty) ...[
                      const Text('Tentang Tempat Ini',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 12),
                      Text(
                        place.description,
                        style: const TextStyle(
                            color: Color(0xFF555555),
                            height: 1.6,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ─── Lokasi Peta ───────────────────────────
                    if (place.lat != 0 && place.lng != 0) ...[
                      const Text('Lokasi',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MapScreen(place: place),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8E8E8)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D8B6F).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.map_outlined,
                                    color: Color(0xFF2D8B6F), size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Lihat Peta & Rute',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF1A1A1A),
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lat: ${place.lat}, Lng: ${place.lng}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Color(0xFF8899A6)),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: Color(0xFF8899A6)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ─── Ulasan ────────────────────────────────
                    Row(
                      children: [
                        const Text('Ulasan',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A))),
                        const Spacer(),
                        Text('${_reviews.length} ulasan',
                            style: const TextStyle(
                                color: Color(0xFF8899A6),
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
                              const Icon(Icons.forum_outlined, size: 48, color: Color(0xFF8899A6)),
                              const SizedBox(height: 12),
                              const Text('Belum ada ulasan.',
                                  style: TextStyle(
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('Jadilah yang pertama me-review!',
                                  style: TextStyle(
                                      color: const Color(0xFF8899A6).withValues(alpha: 0.8),
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._reviews.map((r) => _reviewTile(r)),
                      
                    const SizedBox(height: 80), // Padding untuk Floating Action Button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReviewSheet,
        backgroundColor: const Color(0xFF2D8B6F),
        elevation: 0,
        icon: const Icon(Icons.rate_review_outlined, color: Colors.white, size: 20),
        label: const Text('Tulis Review',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
          Icon(icon, size: 20, color: const Color(0xFF2D8B6F)), // Deep green icon
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.4)),
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
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF5F5DC),
                child: Text(
                  review.username.isNotEmpty
                      ? review.username[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Color(0xFF2D8B6F),
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(review.username,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
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
                style: const TextStyle(color: Color(0xFF555555), fontSize: 14, height: 1.4)),
          ],
        ],
      ),
    );
  }
}