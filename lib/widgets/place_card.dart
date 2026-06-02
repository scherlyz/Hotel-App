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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 15,
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: place.photoUrl.isNotEmpty
                      ? Image.network(
                          place.photoUrl,
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),
                // Badge kategori
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _categoryColor(place.category),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
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
                          fontWeight: FontWeight.bold),
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
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? const Color(0xFFFF4B4B) : const Color(0xFF9E9E9E),
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
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C2833), // Dark Slate
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
                              size: 14, color: Color(0xFFFFC107)), // Bright Yellow
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (place.address.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 14, color: Color(0xFF00A3E4)), // Traveloka Blue
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.address,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF7F8C8D)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F9FF), // Very light blue
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD6EAF8)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 16, color: Color(0xFFFFC107)),
                            const SizedBox(width: 4),
                            Text(
                              place.rating > 0
                                  ? place.rating.toStringAsFixed(1)
                                  : 'Baru',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2980B9), // Darker blue text
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
                          color: Color(0xFFFF5E1F), // Bright Orange (Traveloka style)
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
      height: 170,
      width: double.infinity,
      color: const Color(0xFFF2F4F7),
      child: const Icon(Icons.image_outlined, size: 48, color: Color(0xFFBDC3C7)),
    );
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'hotel':
        return const Color(0xFF00A3E4); // Primary Blue
      case 'wisata':
        return const Color(0xFF2ECC71); // Fresh Green
      case 'restoran':
        return const Color(0xFFFF5E1F); // Orange
      case 'cafe':
        return const Color(0xFF9B59B6); // Purple
      default:
        return const Color(0xFF34495E); // Navy Slate
    }
  }
}