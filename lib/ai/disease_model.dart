enum PredictionStatus { real, uncertain, unavailable }

class PredictionResult {
  final DiseaseModel? disease;
  final PredictionStatus status;
  final String source;
  final String? message;

  const PredictionResult({
    this.disease,
    required this.status,
    required this.source,
    this.message,
  });

  factory PredictionResult.real(DiseaseModel disease, String source) {
    return PredictionResult(
      disease: disease,
      status: PredictionStatus.real,
      source: source,
    );
  }

  factory PredictionResult.uncertain(DiseaseModel disease, String source, {String? message}) {
    return PredictionResult(
      disease: disease,
      status: PredictionStatus.uncertain,
      source: source,
      message: message,
    );
  }

  factory PredictionResult.unavailable({String? message}) {
    return PredictionResult(
      disease: null,
      status: PredictionStatus.unavailable,
      source: 'none',
      message: message ?? 'AI diagnosis is currently unavailable.',
    );
  }
}

class DiseaseModel {
  final String name;
  final String scientificName;
  final String description;
  final String treatment;
  final String dosage;
  final bool isOrganic;
  final String cropType;
  final double confidence;
  final String severity;

  DiseaseModel({
    required this.name,
    this.scientificName = '',
    required this.description,
    required this.treatment,
    this.dosage = '',
    this.isOrganic = false,
    required this.cropType,
    required this.confidence,
    this.severity = 'moderate',
  });

  String get confidenceTier {
    if (confidence >= 0.75) return 'high';
    if (confidence >= 0.40) return 'uncertain';
    return 'low';
  }

  String get confidenceGuidance {
    switch (confidenceTier) {
      case 'high':
        return 'High confidence result. Follow the treatment guidance and keep monitoring the crop.';
      case 'uncertain':
        return 'Uncertain result. Retake the photo in better light or try cloud analysis when online.';
      default:
        return 'Low confidence result. Retake the photo and consider escalating to an agronomist.';
    }
  }

  factory DiseaseModel.fromMap(Map<String, dynamic> map) {
    return DiseaseModel(
      name: map['name'] ?? 'Unknown',
      scientificName: map['scientific_name'] ?? '',
      description: map['description'] ?? 'No description available.',
      treatment: map['treatment'] ?? 'Consult local extension officer.',
      dosage: map['dosage'] ?? '',
      isOrganic: map['is_organic'] ?? false,
      cropType: map['crop_type'] ?? 'Unknown',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: map['severity'] ?? 'moderate',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'scientific_name': scientificName,
      'description': description,
      'treatment': treatment,
      'dosage': dosage,
      'is_organic': isOrganic,
      'crop_type': cropType,
      'confidence': confidence,
      'confidence_tier': confidenceTier,
      'severity': severity,
    };
  }
}

class ScanResult {
  final String id;
  final String imagePath;
  final DiseaseModel disease;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? farmNote;
  final String? plotName;
  final PredictionResult predictionResult;

  ScanResult({
    required this.id,
    required this.imagePath,
    required this.disease,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.farmNote,
    this.plotName,
    required this.predictionResult,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'disease_name': disease.name,
      'crop_type': disease.cropType,
      'confidence': disease.confidence,
      'confidence_tier': disease.confidenceTier,
      'severity': disease.severity,
      'description': disease.description,
      'treatment': disease.treatment,
      'dosage': disease.dosage,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'farm_note': farmNote,
      'plot_name': plotName,
      'prediction_status': predictionResult.status.name,
      'prediction_source': predictionResult.source,
      'prediction_message': predictionResult.message,
    };
  }
}
