class SearchResult {
  final String type;
  final int id;
  final String name;
  final String? county;
  final String? phone;
  final String? email;
  final String? description;
  final String? verificationStatus;
  final double? rating;
  final int? reviewCount;
  final double? distanceKm;

  SearchResult({
    required this.type,
    required this.id,
    required this.name,
    this.county,
    this.phone,
    this.email,
    this.description,
    this.verificationStatus,
    this.rating,
    this.reviewCount,
    this.distanceKm,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      type: json['type'] as String,
      id: json['id'] as int,
      name: json['name'] as String,
      county: json['county'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      description: json['description'] as String?,
      verificationStatus: json['verification_status'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: json['review_count'] as int?,
      distanceKm: json['distance_km'] != null ? (json['distance_km'] as num).toDouble() : null,
    );
  }
}
