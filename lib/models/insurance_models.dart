class InsuranceProvider {
  final int? id;
  final String name;
  final String? registrationNumber;
  final String county;
  final String? subCounty;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? email;
  final String? physicalAddress;
  final String? websiteUrl;
  final String? description;
  final String verificationStatus;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? distanceKm;

  InsuranceProvider({
    this.id,
    required this.name,
    this.registrationNumber,
    required this.county,
    this.subCounty,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.physicalAddress,
    this.websiteUrl,
    this.description,
    this.verificationStatus = 'pending',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.distanceKm,
  });

  factory InsuranceProvider.fromJson(Map<String, dynamic> json) {
    return InsuranceProvider(
      id: json['id'] as int?,
      name: json['name'] as String,
      registrationNumber: json['registration_number'] as String?,
      county: json['county'] as String,
      subCounty: json['sub_county'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      physicalAddress: json['physical_address'] as String?,
      websiteUrl: json['website_url'] as String?,
      description: json['description'] as String?,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      distanceKm: json['distance_km'] != null ? (json['distance_km'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (registrationNumber != null) 'registration_number': registrationNumber,
      'county': county,
      if (subCounty != null) 'sub_county': subCounty,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (physicalAddress != null) 'physical_address': physicalAddress,
      if (websiteUrl != null) 'website_url': websiteUrl,
      if (description != null) 'description': description,
      'verification_status': verificationStatus,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class InsuranceProduct {
  final int? id;
  final int providerId;
  final String name;
  final String productType;
  final String? coverageDescription;
  final String? premiumRangeKes;
  final String? eligibilityCriteria;
  final List<String> coveredPerils;
  final String? claimProcess;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  InsuranceProduct({
    this.id,
    required this.providerId,
    required this.name,
    required this.productType,
    this.coverageDescription,
    this.premiumRangeKes,
    this.eligibilityCriteria,
    this.coveredPerils = const [],
    this.claimProcess,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InsuranceProduct.fromJson(Map<String, dynamic> json) {
    return InsuranceProduct(
      id: json['id'] as int?,
      providerId: json['provider_id'] as int,
      name: json['name'] as String,
      productType: json['product_type'] as String,
      coverageDescription: json['coverage_description'] as String?,
      premiumRangeKes: json['premium_range_kes'] as String?,
      eligibilityCriteria: json['eligibility_criteria'] as String?,
      coveredPerils: json['covered_perils'] != null ? List<String>.from(json['covered_perils']) : [],
      claimProcess: json['claim_process'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'provider_id': providerId,
      'name': name,
      'product_type': productType,
      if (coverageDescription != null) 'coverage_description': coverageDescription,
      if (premiumRangeKes != null) 'premium_range_kes': premiumRangeKes,
      if (eligibilityCriteria != null) 'eligibility_criteria': eligibilityCriteria,
      'covered_perils': coveredPerils,
      if (claimProcess != null) 'claim_process': claimProcess,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
