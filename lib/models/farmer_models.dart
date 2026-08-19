class FarmerProfile {
  final int? id;
  final String userId;
  final String fullName;
  final String county;
  final String? subCounty;
  final String? ward;
  final double? farmSizeHectares;
  final List<String> primaryCrops;
  final int? farmingExperienceYears;
  final String? phoneNumber;
  final String? profilePhotoUrl;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  FarmerProfile({
    this.id,
    required this.userId,
    required this.fullName,
    required this.county,
    this.subCounty,
    this.ward,
    this.farmSizeHectares,
    this.primaryCrops = const [],
    this.farmingExperienceYears,
    this.phoneNumber,
    this.profilePhotoUrl,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FarmerProfile.fromJson(Map<String, dynamic> json) {
    return FarmerProfile(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      county: json['county'] as String,
      subCounty: json['sub_county'] as String?,
      ward: json['ward'] as String?,
      farmSizeHectares: json['farm_size_hectares'] != null ? (json['farm_size_hectares'] as num).toDouble() : null,
      primaryCrops: json['primary_crops'] != null ? List<String>.from(json['primary_crops']) : [],
      farmingExperienceYears: json['farming_experience_years'] as int?,
      phoneNumber: json['phone_number'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'full_name': fullName,
      'county': county,
      if (subCounty != null) 'sub_county': subCounty,
      if (ward != null) 'ward': ward,
      if (farmSizeHectares != null) 'farm_size_hectares': farmSizeHectares,
      'primary_crops': primaryCrops,
      if (farmingExperienceYears != null) 'farming_experience_years': farmingExperienceYears,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Farm {
  final int? id;
  final String userId;
  final int? farmerProfileId;
  final String name;
  final String cropType;
  final String? county;
  final double? latitude;
  final double? longitude;
  final double? areaHectares;
  final DateTime? plantedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Farm({
    this.id,
    required this.userId,
    this.farmerProfileId,
    required this.name,
    required this.cropType,
    this.county,
    this.latitude,
    this.longitude,
    this.areaHectares,
    this.plantedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      farmerProfileId: json['farmer_profile_id'] as int?,
      name: json['name'] as String,
      cropType: json['crop_type'] as String,
      county: json['county'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      areaHectares: json['area_hectares'] != null ? (json['area_hectares'] as num).toDouble() : null,
      plantedAt: json['planted_at'] != null ? DateTime.parse(json['planted_at'] as String) : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (farmerProfileId != null) 'farmer_profile_id': farmerProfileId,
      'name': name,
      'crop_type': cropType,
      if (county != null) 'county': county,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (areaHectares != null) 'area_hectares': areaHectares,
      if (plantedAt != null) 'planted_at': plantedAt!.toIso8601String(),
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
