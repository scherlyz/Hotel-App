import 'package:flutter/material.dart';
import 'map_screen.dart';
import '../models/place.dart';
import '../models/review.dart';
import '../services/api_service.dart';

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
    if (!mounted) return;
    if (result['status'] == 'ok') {
      setState(() => _isFavorite = result['favorited'] == true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isFavorite ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit'),
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
        const SnackBar(content: Text('Review berhasil dikirim!')),
      );
    }
  }

  void _showReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tulis Review',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Rating: ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
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
                        size: 32,
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ceritakan pengalamanmu...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmittingReview ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmittingReview
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Kirim Review',
                          style: TextStyle(color: Colors.white)),
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
          body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _place == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Data tidak ditemukan')),
      );
    }

    final place = _place!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF1565C0),
            actions: [
              IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: place.photoUrl.isNotEmpty
                  ? Image.network(place.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF1565C0),
                            child: const Icon(Icons.hotel,
                                size: 80, color: Colors.white30),
                          ))
                  : Container(
                      color: const Color(0xFF1565C0),
                      child: const Icon(Icons.hotel,
                          size: 80, color: Colors.white30),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E)),
                        ),
                      ),
                      if (place.rating > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFC107), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                place.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF7B6000)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    children: [
                      _chip(place.category, const Color(0xFF1565C0)),
                      if (place.stars > 0)
                        _chip('${place.stars}★ Hotel',
                            const Color(0xFFFFC107)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _infoTile(Icons.location_on_outlined, place.address),
                  if (place.workingHours.isNotEmpty)
                    _infoTile(Icons.access_time, place.workingHours),
                  if (place.phone.isNotEmpty)
                    _infoTile(Icons.phone_outlined, place.phone),
                  if (place.website.isNotEmpty)
                    _infoTile(Icons.language, place.website),
                  _infoTile(Icons.payments_outlined, place.priceRange),

                  const SizedBox(height: 16),

                  if (place.description.isNotEmpty) ...[
                    const Text('Tentang Tempat Ini',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      place.description,
                      style: const TextStyle(
                          color: Colors.grey, height: 1.6, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (place.lat != 0 && place.lng != 0) ...[
                    const Text('Lokasi',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MapScreen(place: place),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.map_outlined,
                                color: Color(0xFF1565C0)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lat: ${place.lat}, Lng: ${place.lng}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  const Text(
                                    'Tap untuk lihat peta & rute',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF1565C0),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Color(0xFF1565C0)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Row(
                    children: [
                      const Text('Ulasan',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text('${_reviews.length} ulasan',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_reviews.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('Belum ada ulasan. Jadilah yang pertama!',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._reviews.map((r) => _reviewTile(r)),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReviewSheet,
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.rate_review, color: Colors.white),
        label: const Text('Tulis Review',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _infoTile(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1565C0)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _reviewTile(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
                child: Text(
                  review.username.isNotEmpty
                      ? review.username[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Color(0xFF1565C0), fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(review.username,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Row(
                children: List.generate(
                  review.rating.round().clamp(0, 5),
                  (_) => const Icon(Icons.star_rounded,
                      size: 14, color: Color(0xFFFFC107)),
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}