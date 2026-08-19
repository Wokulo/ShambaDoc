class Sacco {
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
  final String? membershipRequirements;
  final List<String> servicesOffered;
  final String verificationStatus;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? distanceKm;

  Sacco({
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
    this.membershipRequirements,
    this.servicesOffered = const [],
    this.verificationStatus = 'pending',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.distanceKm,
  });

  factory Sacco.fromJson(Map<String, dynamic> json) {
    return Sacco(
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
      membershipRequirements: json['membership_requirements'] as String?,
      servicesOffered: json['services_offered'] != null ? List<String>.from(json['services_offered']) : [],
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
      if (membershipRequirements != null) 'membership_requirements': membershipRequirements,
      'services_offered': servicesOffered,
      'verification_status': verificationStatus,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class FinancialProduct {
  final int? id;
  final int saccoId;
  final String name;
  final String productType;
  final String? description;
  final double? interestRateMin;
  final double? interestRateMax;
  final int? loanLimitMinKes;
  final int? loanLimitMaxKes;
  final int? repaymentPeriodMonths;
  final String? eligibilityCriteria;
  final List<String> requiredDocuments;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  FinancialProduct({
    this.id,
    required this.saccoId,
    required this.name,
    required this.productType,
    this.description,
    this.interestRateMin,
    this.interestRateMax,
    this.loanLimitMinKes,
    this.loanLimitMaxKes,
    this.repaymentPeriodMonths,
    this.eligibilityCriteria,
    this.requiredDocuments = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FinancialProduct.fromJson(Map<String, dynamic> json) {
    return FinancialProduct(
      id: json['id'] as int?,
      saccoId: json['sacco_id'] as int,
      name: json['name'] as String,
      productType: json['product_type'] as String,
      description: json['description'] as String?,
      interestRateMin: json['interest_rate_min'] != null ? (json['interest_rate_min'] as num).toDouble() : null,
      interestRateMax: json['interest_rate_max'] != null ? (json['interest_rate_max'] as num).toDouble() : null,
      loanLimitMinKes: json['loan_limit_min_kes'] as int?,
      loanLimitMaxKes: json['loan_limit_max_kes'] as int?,
      repaymentPeriodMonths: json['repayment_period_months'] as int?,
      eligibilityCriteria: json['eligibility_criteria'] as String?,
      requiredDocuments: json['required_documents'] != null ? List<String>.from(json['required_documents']) : [],
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'sacco_id': saccoId,
      'name': name,
      'product_type': productType,
      if (description != null) 'description': description,
      if (interestRateMin != null) 'interest_rate_min': interestRateMin,
      if (interestRateMax != null) 'interest_rate_max': interestRateMax,
      if (loanLimitMinKes != null) 'loan_limit_min_kes': loanLimitMinKes,
      if (loanLimitMaxKes != null) 'loan_limit_max_kes': loanLimitMaxKes,
      if (repaymentPeriodMonths != null) 'repayment_period_months': repaymentPeriodMonths,
      if (eligibilityCriteria != null) 'eligibility_criteria': eligibilityCriteria,
      'required_documents': requiredDocuments,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
