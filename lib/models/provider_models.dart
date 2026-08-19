class Agronomist {
  final int? id;
  final String? userId;
  final String fullName;
  final String? professionalTitle;
  final String? qualification;
  final List<String> specialization;
  final String county;
  final String? subCounty;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? email;
  final String availability;
  final int? yearsOfExperience;
  final String? profilePhotoUrl;
  final String? bio;
  final String verificationStatus;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? distanceKm;

  Agronomist({
    this.id,
    this.userId,
    required this.fullName,
    this.professionalTitle,
    this.qualification,
    this.specialization = const [],
    required this.county,
    this.subCounty,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.availability = 'available',
    this.yearsOfExperience,
    this.profilePhotoUrl,
    this.bio,
    this.verificationStatus = 'pending',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.distanceKm,
  });

  factory Agronomist.fromJson(Map<String, dynamic> json) {
    return Agronomist(
      id: json['id'] as int?,
      userId: json['user_id'] as String?,
      fullName: json['full_name'] as String,
      professionalTitle: json['professional_title'] as String?,
      qualification: json['qualification'] as String?,
      specialization: json['specialization'] != null ? List<String>.from(json['specialization']) : [],
      county: json['county'] as String,
      subCounty: json['sub_county'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      availability: json['availability'] as String? ?? 'available',
      yearsOfExperience: json['years_of_experience'] as int?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      bio: json['bio'] as String?,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      distanceKm: json['distance_km'] != null ? (json['distance_km'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'full_name': fullName,
      if (professionalTitle != null) 'professional_title': professionalTitle,
      if (qualification != null) 'qualification': qualification,
      'specialization': specialization,
      'county': county,
      if (subCounty != null) 'sub_county': subCounty,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      'availability': availability,
      if (yearsOfExperience != null) 'years_of_experience': yearsOfExperience,
      if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
      if (bio != null) 'bio': bio,
      'verification_status': verificationStatus,
      'rating': rating,
      'review_count': reviewCount,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class GovernmentOfficer {
  final int? id;
  final String? userId;
  final String fullName;
  final String? professionalTitle;
  final String designation;
  final String? department;
  final String county;
  final String? subCounty;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? email;
  final String? officeAddress;
  final String verificationStatus;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? distanceKm;

  GovernmentOfficer({
    this.id,
    this.userId,
    required this.fullName,
    this.professionalTitle,
    required this.designation,
    this.department,
    required this.county,
    this.subCounty,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.officeAddress,
    this.verificationStatus = 'pending',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.distanceKm,
  });

  factory GovernmentOfficer.fromJson(Map<String, dynamic> json) {
    return GovernmentOfficer(
      id: json['id'] as int?,
      userId: json['user_id'] as String?,
      fullName: json['full_name'] as String,
      professionalTitle: json['professional_title'] as String?,
      designation: json['designation'] as String,
      department: json['department'] as String?,
      county: json['county'] as String,
      subCounty: json['sub_county'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      officeAddress: json['office_address'] as String?,
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
      if (userId != null) 'user_id': userId,
      'full_name': fullName,
      if (professionalTitle != null) 'professional_title': professionalTitle,
      'designation': designation,
      if (department != null) 'department': department,
      'county': county,
      if (subCounty != null) 'sub_county': subCounty,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (officeAddress != null) 'office_address': officeAddress,
      'verification_status': verificationStatus,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
