import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../core/constants/app_colors.dart';
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
        height: 260,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .18),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              /// IMAGE
              place.photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ApiService.resolveImageUrl(place.photoUrl),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _loadingPlaceholder(),
                      errorWidget: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),

              /// FAVORITE — glass blur, tanpa stroke
              Positioned(
                right: 16,
                top: 16,
                child: onFavoriteTap != null
                    ? GestureDetector(
                        onTap: onFavoriteTap,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(19),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color:
                                    Colors.grey.shade200.withValues(alpha: .35),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color:
                                    isFavorite ? Colors.redAccent : Colors.white,
                                size: 19,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
  
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 150, // sedikit ditambah dari 130, karena bagian atas kini fade-in
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.white],
                      stops: [0.0, 0.45], // 0–45% dari tinggi panel = area transisi blur
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(26),
                      bottomRight: Radius.circular(26),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: .0),
                              Colors.black.withValues(alpha: .55),
                            ],
                            stops: const [0.0, 0.5],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              place.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              place.priceRange,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppColors.gold, size: 17),
                                const SizedBox(width: 3),
                                Text(
                                  place.rating > 0
                                      ? place.rating.toStringAsFixed(1)
                                      : "New",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: const BoxDecoration(
                                    color: Colors.white70,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.location_on_rounded,
                                    color: Colors.white70, size: 15),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    place.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadingPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFFF4F4F4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.hotel, size: 58, color: AppColors.textHint),
          SizedBox(height: 12),
          Text("No Image", style: TextStyle(color: AppColors.textHint)),
        ],
      ),
    );
  }
}