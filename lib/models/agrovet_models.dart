class Agrovet {
  final int? id;
  final int? dealerId;
  final String businessName;
  final String? ownerName;
  final String? licenseNumber;
  final bool licenseVerified;
  final String physicalAddress;
  final String county;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? email;
  final dynamic openingHours;
  final bool deliveryAvailable;
  final int? deliveryRadiusKm;
  final String verificationStatus;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? dealerName;
  final String? dealerPhone;
  final String? dealerAddress;
  final double? distanceKm;

  Agrovet({
    this.id,
    this.dealerId,
    required this.businessName,
    this.ownerName,
    this.licenseNumber,
    this.licenseVerified = false,
    required this.physicalAddress,
    required this.county,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.openingHours,
    this.deliveryAvailable = false,
    this.deliveryRadiusKm,
    this.verificationStatus = 'pending',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.dealerName,
    this.dealerPhone,
    this.dealerAddress,
    this.distanceKm,
  });

  factory Agrovet.fromJson(Map<String, dynamic> json) {
    return Agrovet(
      id: json['id'] as int?,
      dealerId: json['dealer_id'] as int?,
      businessName: json['business_name'] as String,
      ownerName: json['owner_name'] as String?,
      licenseNumber: json['license_number'] as String?,
      licenseVerified: json['license_verified'] as bool? ?? false,
      physicalAddress: json['physical_address'] as String,
      county: json['county'] as String,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      openingHours: json['opening_hours'],
      deliveryAvailable: json['delivery_available'] as bool? ?? false,
      deliveryRadiusKm: json['delivery_radius_km'] as int?,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      dealerName: json['dealer_name'] as String?,
      dealerPhone: json['dealer_phone'] as String?,
      dealerAddress: json['dealer_address'] as String?,
      distanceKm: json['distance_km'] != null ? (json['distance_km'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (dealerId != null) 'dealer_id': dealerId,
      'business_name': businessName,
      if (ownerName != null) 'owner_name': ownerName,
      if (licenseNumber != null) 'license_number': licenseNumber,
      'license_verified': licenseVerified,
      'physical_address': physicalAddress,
      'county': county,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (openingHours != null) 'opening_hours': openingHours,
      'delivery_available': deliveryAvailable,
      if (deliveryRadiusKm != null) 'delivery_radius_km': deliveryRadiusKm,
      'verification_status': verificationStatus,
      'rating': rating,
      'review_count': reviewCount,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class AgrovetProduct {
  final int? id;
  final int agrovetId;
  final String name;
  final String category;
  final String? description;
  final double? priceKes;
  final String currency;
  final String stockStatus;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AgrovetProduct({
    this.id,
    required this.agrovetId,
    required this.name,
    required this.category,
    this.description,
    this.priceKes,
    this.currency = 'KES',
    this.stockStatus = 'in_stock',
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AgrovetProduct.fromJson(Map<String, dynamic> json) {
    return AgrovetProduct(
      id: json['id'] as int?,
      agrovetId: json['agrovet_id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      priceKes: json['price_kes'] != null ? (json['price_kes'] as num).toDouble() : null,
      currency: json['currency'] as String? ?? 'KES',
      stockStatus: json['stock_status'] as String? ?? 'in_stock',
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'agrovet_id': agrovetId,
      'name': name,
      'category': category,
      if (description != null) 'description': description,
      if (priceKes != null) 'price_kes': priceKes,
      'currency': currency,
      'stock_status': stockStatus,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
