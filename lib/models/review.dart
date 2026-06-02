class Review {
  final int id;
  final int placeId;
  final String placeName;
  final String username;
  final double rating;
  final String comment;
  final String createdAt;

  Review({
    this.id = 0,
    this.placeId = 0,
    this.placeName = '',
    required this.username,
    required this.rating,
    required this.comment,
    this.createdAt = '',
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      placeId: int.tryParse(json['place_id']?.toString() ?? '0') ?? 0,
      placeName: json['place_name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      comment: json['comment']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}