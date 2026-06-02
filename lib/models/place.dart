class Place {
  final int id;
  final String name;
  final String category;
  final int stars;
  final String address;
  final double lat;
  final double lng;
  final double rating;
  final int priceMin;
  final int priceMax;
  final String description;
  final String photoUrl;
  final String phone;
  final String website;
  final String workingHours;

  Place({
    required this.id,
    required this.name,
    this.category = '',
    this.stars = 0,
    this.address = '',
    this.lat = 0.0,
    this.lng = 0.0,
    this.rating = 0.0,
    this.priceMin = 0,
    this.priceMax = 0,
    this.description = '',
    this.photoUrl = '',
    this.phone = '',
    this.website = '',
    this.workingHours = '',
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      stars: _parseInt(json['stars']),
      address: json['address']?.toString() ?? '',
      lat: _parseDouble(json['lat']),
      lng: _parseDouble(json['lng']),
      rating: _parseDouble(json['rating']),
      priceMin: _parseInt(json['price_min']),
      priceMax: _parseInt(json['price_max']),
      description: json['description']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      workingHours: json['working_hours']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  final result = double.tryParse(value.toString()) ?? 0.0;
  // Jika nilai terlalu besar, kemungkinan tanpa desimal (dari Sheets)
  if (result.abs() > 1000) return result / 10000000;
  return result;
}

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'stars': stars,
        'address': address,
        'lat': lat,
        'lng': lng,
        'rating': rating,
        'price_min': priceMin,
        'price_max': priceMax,
        'description': description,
        'photo_url': photoUrl,
        'phone': phone,
        'website': website,
        'working_hours': workingHours,
      };

  String get priceRange {
    if (priceMin == 0 && priceMax == 0) return 'Hubungi kami';
    if (priceMax == 0) return 'Rp ${_formatPrice(priceMin)}+';
    return 'Rp ${_formatPrice(priceMin)} – ${_formatPrice(priceMax)}';
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}