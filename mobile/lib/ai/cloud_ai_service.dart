import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'disease_model.dart';

class CloudAIService {
  static const String _plantIdApiKey = String.fromEnvironment('PLANT_ID_API_KEY');
  static const String _plantIdUrl = 'https://api.plant.id/v2/health_assessment';
  static const String _backendUrl = String.fromEnvironment(
    'SHAMBADOC_API_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  static Future<DiseaseModel?> cloudPredict(File imageFile) async {
    if (_plantIdApiKey.isEmpty) return null;

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_plantIdUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_key': _plantIdApiKey,
          'images': [base64Image],
          'modifiers': ['similar_images'],
          'language': 'en',
          'disease_details': ['description', 'treatment'],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final healthAssessment = data['health_assessment'];

        if (healthAssessment != null && healthAssessment['diseases'] != null) {
          final diseases = healthAssessment['diseases'] as List;
          if (diseases.isNotEmpty) {
            final topDisease = diseases[0];
            return DiseaseModel(
              name: topDisease['name'] ?? 'Unknown',
              description: topDisease['disease_details']?['description']?['value'] ?? 'No description',
              treatment: _extractTreatment(topDisease),
              cropType: 'Unknown',
              confidence: (topDisease['probability'] ?? 0.0).toDouble(),
            );
          }
        }
      }
      return null;
    } catch (e) {
      print('Cloud AI error: $e');
      return null;
    }
  }

  static Future<void> logScan(Map<String, dynamic> scanData) async {
    try {
      await http.post(
        Uri.parse('$_backendUrl/diagnose/log'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(scanData),
      );
    } catch (e) {
      print('Failed to log scan: $e');
    }
  }

  static String _extractTreatment(dynamic diseaseData) {
    final treatment = diseaseData['disease_details']?['treatment'];
    if (treatment == null) return 'Consult local expert';

    final chemical = treatment['chemical']?['value'];
    final biological = treatment['biological']?['value'];
    final prevention = treatment['prevention']?['value'];

    return [chemical, biological, prevention].where((t) => t != null).join('. ');
  }
}
