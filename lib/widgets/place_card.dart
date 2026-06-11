import 'package:flutter/material.dart';
import '../models/place.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const PlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // Disesuaikan dengan radius card lain
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Gambar ─────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: place.photoUrl.isNotEmpty
                      ? Image.network(
                          place.photoUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),
                // Badge kategori
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _categoryColor(place.category),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      place.category.isEmpty ? 'Lainnya' : place.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Tombol favorit
                if (onFavoriteTap != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFavorite ? const Color(0xFFDC2626) : const Color(0xFFAAAAAA), // Soft red / muted grey
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ─── Info ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A), // Dark text
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (place.stars > 0) ...[
                        const SizedBox(width: 6),
                        ...List.generate(
                          place.stars.clamp(0, 5),
                          (_) => const Icon(Icons.star_rounded,
                              size: 14, color: Color(0xFFD4AF37)), // Warm gold
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (place.address.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 14, color: Color(0xFF8899A6)), // Muted icon
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.address,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF8899A6)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D8B6F).withValues(alpha: 0.1), // Light green tint
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 16, color: Color(0xFFD4AF37)), // Warm gold
                            const SizedBox(width: 4),
                            Text(
                              place.rating > 0
                                  ? place.rating.toStringAsFixed(1)
                                  : 'Baru',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D8B6F), // Deep green text
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        place.priceRange,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D8B6F), // Deep green for emphasis
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 160,
      width: double.infinity,
      color: const Color(0xFFF5F5DC), // Cream beige placeholder
      child: const Icon(Icons.image_outlined, size: 48, color: Color(0xFFAAAAAA)),
    );
  }

  Color _categoryColor(String category) {
    // Palet warna earth-tone sesuai kategori
    switch (category.toLowerCase()) {
      case 'hotel':
        return const Color(0xFF2D8B6F); // Deep Green
      case 'wisata':
        return const Color(0xFFD4AF37); // Warm Gold / Mustard
      case 'restoran':
        return const Color(0xFFC05640); // Terracotta / Soft Red-Orange
      case 'cafe':
        return const Color(0xFF8B7355); // Warm Mocha Brown
      default:
        return const Color(0xFF8899A6); // Muted Grey-Blue
    }
  }
}