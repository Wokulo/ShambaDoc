import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shambadoc/services/api_service.dart';
import 'disease_model.dart';

class CloudAIService {
  static const String _plantIdApiKey =
      String.fromEnvironment('PLANT_ID_API_KEY');
  static const String _plantIdUrl =
      'https://api.plant.id/v2/health_assessment';

  // ── Cloud prediction via Plant.id ──────────────────────────────────────────

  static Future<DiseaseModel?> cloudPredict(File imageFile) async {
    if (_plantIdApiKey.isEmpty) {
      debugLog('Plant.id API key not set — skipping cloud prediction');
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
          return DiseaseModel(
            name:        top['name'] ?? 'Unknown',
            description: top['disease_details']?['description']?['value'] ??
                'No description available.',
            treatment:   _extractTreatment(top),
            cropType:    'Unknown',
            confidence:  (top['probability'] as num?)?.toDouble() ?? 0.0,
          );
        }
      }
    } catch (e) {
      debugLog('Cloud predict error: $e');
    }
    return null;
  }

  // ── Log scan to backend ────────────────────────────────────────────────────

  static Future<void> logScan(Map<String, dynamic> scanData) async {
    try {
      await ApiService.logScan(scanData);
    } catch (e) {
      debugLog('logScan error: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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

  static void debugLog(String msg) => print('[CloudAI] $msg');
}
