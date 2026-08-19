import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shambadoc/services/api_service.dart';
import 'disease_model.dart';

class CloudAIService {
  static const String _plantIdApiKey =
      String.fromEnvironment('PLANT_ID_API_KEY');
  static const String _plantIdUrl =
      'https://api.plant.id/v2/health_assessment';

  static Future<PredictionResult?> cloudPredict(File imageFile) async {
    if (_plantIdApiKey.isEmpty) {
      debugPrint('Plant.id API key not set — skipping cloud prediction');
      return null;
    }
    try {
      final bytes       = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http
          .post(
            Uri.parse(_plantIdUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'api_key': _plantIdApiKey,
              'images': [base64Image],
              'modifiers': ['similar_images'],
              'language': 'en',
              'disease_details': ['description', 'treatment'],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data             = jsonDecode(response.body);
        final healthAssessment = data['health_assessment'];

        if (healthAssessment != null &&
            (healthAssessment['diseases'] as List?)?.isNotEmpty == true) {
          final top = (healthAssessment['diseases'] as List)[0];
          final confidence = (top['probability'] as num?)?.toDouble() ?? 0.0;
          final disease = DiseaseModel(
            name:        top['name'] ?? 'Unknown',
            description: top['disease_details']?['description']?['value'] ??
                'No description available.',
            treatment:   _extractTreatment(top),
            cropType:    'Unknown',
            confidence:  confidence,
          );
          final status = confidence < 0.40
              ? PredictionStatus.unavailable
              : (confidence < 0.75 ? PredictionStatus.uncertain : PredictionStatus.real);
          return PredictionResult(
            disease: disease,
            status: status,
            source: 'plant_id',
            message: status == PredictionStatus.unavailable
                ? 'AI could not confidently identify the disease.'
                : null,
          );
        }
      }
    } catch (e) {
      debugPrint('Cloud predict error: $e');
    }
    return null;
  }

  static Future<void> logScan(Map<String, dynamic> scanData) async {
    try {
      await ApiService.logScan(scanData);
    } catch (e) {
      debugPrint('logScan error: $e');
    }
  }

  static String _extractTreatment(dynamic d) {
    final t        = d['disease_details']?['treatment'];
    if (t == null) return 'Consult local extension officer.';
    final chemical   = t['chemical']?['value'];
    final biological = t['biological']?['value'];
    final prevention = t['prevention']?['value'];
    return [chemical, biological, prevention]
        .where((s) => s != null && s.toString().isNotEmpty)
        .join('. ');
  }

  static void debugLog(String msg) => debugPrint('[CloudAI] $msg');
}
