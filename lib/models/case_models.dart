class DiseaseCase {
  final int? id;
  final String? scanId;
  final String userId;
  final String? assignedTo;
  final String status;
  final String? farmerNote;
  final String? agronomistDiagnosis;
  final String? agronomistAdvice;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  DiseaseCase({
    this.id,
    this.scanId,
    required this.userId,
    this.assignedTo,
    this.status = 'open',
    this.farmerNote,
    this.agronomistDiagnosis,
    this.agronomistAdvice,
    required this.createdAt,
    this.resolvedAt,
  });

  factory DiseaseCase.fromJson(Map<String, dynamic> json) {
    return DiseaseCase(
      id: json['id'] as int?,
      scanId: json['scan_id'] as String?,
      userId: json['user_id'] as String,
      assignedTo: json['assigned_to'] as String?,
      status: json['status'] as String? ?? 'open',
      farmerNote: json['farmer_note'] as String?,
      agronomistDiagnosis: json['agronomist_diagnosis'] as String?,
      agronomistAdvice: json['agronomist_advice'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (scanId != null) 'scan_id': scanId,
      'user_id': userId,
      if (assignedTo != null) 'assigned_to': assignedTo,
      'status': status,
      if (farmerNote != null) 'farmer_note': farmerNote,
      if (agronomistDiagnosis != null) 'agronomist_diagnosis': agronomistDiagnosis,
      if (agronomistAdvice != null) 'agronomist_advice': agronomistAdvice,
      'created_at': createdAt.toIso8601String(),
      if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
    };
  }
}
