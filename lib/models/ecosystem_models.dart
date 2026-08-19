class Advisory {
  final int? id;
  final String? authorId;
  final String authorType;
  final String title;
  final String content;
  final List<String> cropTypes;
  final List<String> counties;
  final String? severityLevel;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Advisory({
    this.id,
    this.authorId,
    this.authorType = 'government_officer',
    required this.title,
    required this.content,
    this.cropTypes = const [],
    this.counties = const [],
    this.severityLevel,
    this.isPublished = false,
    this.publishedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Advisory.fromJson(Map<String, dynamic> json) {
    return Advisory(
      id: json['id'] as int?,
      authorId: json['author_id'] as String?,
      authorType: json['author_type'] as String? ?? 'government_officer',
      title: json['title'] as String,
      content: json['content'] as String,
      cropTypes: json['crop_types'] != null ? List<String>.from(json['crop_types']) : [],
      counties: json['counties'] != null ? List<String>.from(json['counties']) : [],
      severityLevel: json['severity_level'] as String?,
      isPublished: json['is_published'] as bool? ?? false,
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at'] as String) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (authorId != null) 'author_id': authorId,
      'author_type': authorType,
      'title': title,
      'content': content,
      'crop_types': cropTypes,
      'counties': counties,
      if (severityLevel != null) 'severity_level': severityLevel,
      'is_published': isPublished,
      if (publishedAt != null) 'published_at': publishedAt!.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class GovernmentProgram {
  final int? id;
  final String title;
  final String description;
  final String programType;
  final List<String> targetCrops;
  final List<String> targetCounties;
  final String? eligibilityCriteria;
  final String? benefitsDescription;
  final DateTime? applicationStartDate;
  final DateTime? applicationEndDate;
  final DateTime? programStartDate;
  final DateTime? programEndDate;
  final String? contactPerson;
  final String? contactPhone;
  final String? contactEmail;
  final String? applicationUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  GovernmentProgram({
    this.id,
    required this.title,
    required this.description,
    required this.programType,
    this.targetCrops = const [],
    this.targetCounties = const [],
    this.eligibilityCriteria,
    this.benefitsDescription,
    this.applicationStartDate,
    this.applicationEndDate,
    this.programStartDate,
    this.programEndDate,
    this.contactPerson,
    this.contactPhone,
    this.contactEmail,
    this.applicationUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GovernmentProgram.fromJson(Map<String, dynamic> json) {
    return GovernmentProgram(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String,
      programType: json['program_type'] as String,
      targetCrops: json['target_crops'] != null ? List<String>.from(json['target_crops']) : [],
      targetCounties: json['target_counties'] != null ? List<String>.from(json['target_counties']) : [],
      eligibilityCriteria: json['eligibility_criteria'] as String?,
      benefitsDescription: json['benefits_description'] as String?,
      applicationStartDate: json['application_start_date'] != null ? DateTime.parse(json['application_start_date'] as String) : null,
      applicationEndDate: json['application_end_date'] != null ? DateTime.parse(json['application_end_date'] as String) : null,
      programStartDate: json['program_start_date'] != null ? DateTime.parse(json['program_start_date'] as String) : null,
      programEndDate: json['program_end_date'] != null ? DateTime.parse(json['program_end_date'] as String) : null,
      contactPerson: json['contact_person'] as String?,
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      applicationUrl: json['application_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'program_type': programType,
      'target_crops': targetCrops,
      'target_counties': targetCounties,
      if (eligibilityCriteria != null) 'eligibility_criteria': eligibilityCriteria,
      if (benefitsDescription != null) 'benefits_description': benefitsDescription,
      if (applicationStartDate != null) 'application_start_date': applicationStartDate!.toIso8601String(),
      if (applicationEndDate != null) 'application_end_date': applicationEndDate!.toIso8601String(),
      if (programStartDate != null) 'program_start_date': programStartDate!.toIso8601String(),
      if (programEndDate != null) 'program_end_date': programEndDate!.toIso8601String(),
      if (contactPerson != null) 'contact_person': contactPerson,
      if (contactPhone != null) 'contact_phone': contactPhone,
      if (contactEmail != null) 'contact_email': contactEmail,
      if (applicationUrl != null) 'application_url': applicationUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class AgriculturalEvent {
  final int? id;
  final String title;
  final String description;
  final String eventType;
  final String organizerType;
  final String? organizerId;
  final String county;
  final String? subCounty;
  final double? latitude;
  final double? longitude;
  final DateTime eventDate;
  final DateTime? endDate;
  final String? venue;
  final bool registrationRequired;
  final String? registrationUrl;
  final int? maxParticipants;
  final bool isFree;
  final int? priceKes;
  final DateTime createdAt;
  final DateTime updatedAt;

  AgriculturalEvent({
    this.id,
    required this.title,
    required this.description,
    required this.eventType,
    this.organizerType = 'government',
    this.organizerId,
    required this.county,
    this.subCounty,
    this.latitude,
    this.longitude,
    required this.eventDate,
    this.endDate,
    this.venue,
    this.registrationRequired = false,
    this.registrationUrl,
    this.maxParticipants,
    this.isFree = true,
    this.priceKes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AgriculturalEvent.fromJson(Map<String, dynamic> json) {
    return AgriculturalEvent(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String,
      eventType: json['event_type'] as String,
      organizerType: json['organizer_type'] as String? ?? 'government',
      organizerId: json['organizer_id'] as String?,
      county: json['county'] as String,
      subCounty: json['sub_county'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      eventDate: DateTime.parse(json['event_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      venue: json['venue'] as String?,
      registrationRequired: json['registration_required'] as bool? ?? false,
      registrationUrl: json['registration_url'] as String?,
      maxParticipants: json['max_participants'] as int?,
      isFree: json['is_free'] as bool? ?? true,
      priceKes: json['price_kes'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'event_type': eventType,
      'organizer_type': organizerType,
      if (organizerId != null) 'organizer_id': organizerId,
      'county': county,
      if (subCounty != null) 'sub_county': subCounty,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'event_date': eventDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      if (venue != null) 'venue': venue,
      'registration_required': registrationRequired,
      if (registrationUrl != null) 'registration_url': registrationUrl,
      if (maxParticipants != null) 'max_participants': maxParticipants,
      'is_free': isFree,
      if (priceKes != null) 'price_kes': priceKes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
