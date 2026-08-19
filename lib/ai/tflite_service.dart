import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'disease_model.dart';

class TFLiteService {
  static final TFLiteService _instance = TFLiteService._internal();
  factory TFLiteService() => _instance;
  TFLiteService._internal();

  static const String apiUrl = 'https://shambadoc-api.onrender.com/predict';
  static const String healthUrl = 'https://shambadoc-api.onrender.com/health';
  static const String labelPath = 'assets/models/labels.txt';

  List<String> _labels = [];
  bool _isInitialized = false;
  bool _modelAvailable = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final labelData = await rootBundle.loadString(labelPath);
      _labels = labelData.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final response = await http.get(Uri.parse(healthUrl))
          .timeout(const Duration(seconds: 3));
      _modelAvailable = response.statusCode == 200;
      debugPrint('✅ API reachable, classes: ${_labels.length}');
    } catch (e) {
      _modelAvailable = false;
      debugPrint('⚠️ API not reachable: $e');
    }
    _isInitialized = true;
  }

  Future<PredictionResult> predict(File imageFile) async {
    if (!_isInitialized) await init();
    if (!_modelAvailable) {
      debugPrint('⚠️ API unavailable, using development fallback');
      return _mockPrediction();
    }
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) throw Exception('API error ${streamed.statusCode}');
      final json = jsonDecode(body) as Map<String, dynamic>;
      final label = json['label'] as String;
      final confidence = (json['confidence'] as num).toDouble();
      debugPrint('✅ Predicted: $label (${(confidence*100).toStringAsFixed(1)}%)');
      final disease = _parseLabel(label, confidence);
      final status = confidence < 0.40
          ? PredictionStatus.unavailable
          : (confidence < 0.75 ? PredictionStatus.uncertain : PredictionStatus.real);
      return PredictionResult(
        disease: disease,
        status: status,
        source: 'cloud_ai',
        message: status == PredictionStatus.unavailable
            ? 'AI could not confidently identify the disease.'
            : null,
      );
    } catch (e, stack) {
      debugPrint('❌ predict error: $e');
      debugPrint('$stack');
      return _mockPrediction();
    }
  }

  /// DEVELOPMENT FALLBACK ONLY — never present this as a real AI diagnosis
  /// in production. If a real AI result is unavailable, the UI should clearly
  /// state that diagnosis could not be confirmed rather than showing fabricated
  /// disease results as authoritative.
  PredictionResult _mockPrediction() {
    return PredictionResult.unavailable(
      message: 'Development fallback active — no real AI diagnosis available.',
    );
  }

  DiseaseModel _parseLabel(String label, double confidence) {
    final parts = label.split('___');
    final cropType = parts.isNotEmpty ? _formatName(parts[0]) : 'Unknown';
    final diseasePart = parts.length > 1 ? parts[1] : 'healthy';
    final diseaseName = _formatName(diseasePart.replaceAll('_', ' '));
    return DiseaseModel(
      name: diseaseName,
      cropType: cropType,
      confidence: confidence,
      description: _getDescription(diseaseName, cropType),
      treatment: _getTreatment(diseaseName),
      dosage: _getDosage(diseaseName),
      isOrganic: _isOrganic(diseaseName),
      severity: _getSeverity(diseaseName, confidence),
    );
  }

  String _formatName(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  String _getDescription(String disease, String crop) {
    final d = disease.toLowerCase();
    if (d.contains('healthy')) return '$crop appears healthy. No signs of disease detected.';
    final map = {
      'early blight': 'Early blight caused by Alternaria solani. Dark brown spots with concentric rings.',
      'late blight': 'Late blight caused by Phytophthora infestans. Water-soaked lesions spread rapidly.',
      'common rust': 'Common rust caused by Puccinia sorghi. Pustules on both leaf surfaces.',
      'bacterial spot': 'Bacterial spot causes water-soaked lesions that turn brown with yellow halos.',
      'mosaic virus': 'Mosaic virus causes mottled yellow-green patterns and stunted growth.',
      'gray leaf spot': 'Gray leaf spot: rectangular lesions between leaf veins.',
      'black rot': 'Black rot: V-shaped yellow lesions and black vein discoloration.',
      'powdery mildew': 'Powdery mildew: white powdery coating on leaves and stems.',
    };
    for (final k in map.keys) { if (d.contains(k)) return map[k]!; }
    return 'Detected $disease on $crop. Consult your local extension officer.';
  }

  String _getTreatment(String disease) {
    final d = disease.toLowerCase();
    if (d.contains('healthy')) return 'No treatment needed. Maintain good agronomic practices.';
    final map = {
      'early blight': 'Apply Mancozeb (Dithane M-45) or Copper-based fungicide.',
      'late blight': 'Apply Ridomil Gold or Metalaxyl immediately. Remove infected material.',
      'common rust': 'Apply Propiconazole or Tebuconazole at first sign.',
      'bacterial spot': 'Apply Copper hydroxide. Avoid overhead irrigation.',
      'mosaic virus': 'No chemical cure. Uproot infected plants. Control aphids with Imidacloprid.',
      'gray leaf spot': 'Apply Strobilurin fungicide. Practice crop rotation.',
      'black rot': 'Apply Copper-based fungicide. Remove infected debris.',
      'powdery mildew': 'Apply Sulphur-based fungicide or Potassium bicarbonate.',
    };
    for (final k in map.keys) { if (d.contains(k)) return map[k]!; }
    return 'Consult your nearest agro-dealer for treatment recommendations.';
  }

  String _getDosage(String disease) {
    if (disease.toLowerCase().contains('healthy')) return 'N/A';
    if (disease.toLowerCase().contains('virus')) return 'N/A — no chemical treatment';
    return '50g per 20L knapsack sprayer. Spray every 7–14 days.';
  }

  bool _isOrganic(String disease) => disease.toLowerCase().contains('healthy');

  String _getSeverity(String disease, double confidence) {
    final d = disease.toLowerCase();
    if (d.contains('healthy')) return 'none';
    if (d.contains('late blight') || d.contains('virus')) return 'severe';
    return 'moderate';
  }

  void dispose() {
    _isInitialized = false;
    _modelAvailable = false;
  }
}
