import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'SHAMBADOC_API_URL',
    defaultValue: 'http://localhost:3000/api',
  );
  static const Map<String, String> headers = {'Content-Type': 'application/json'};

  static Future<Map<String, dynamic>?> getDealers({double? lat, double? lng, double radius = 50}) async {
    try {
      final uri = Uri.parse('$baseUrl/dealers').replace(queryParameters: {
        if (lat != null) 'lat': lat.toString(),
        if (lng != null) 'lng': lng.toString(),
        'radius': radius.toString(),
      });

      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('API Error: $e');
      return null;
    }
  }

  static Future<bool> submitFeedback({required String scanId, required bool wasCorrect, String? correctDisease}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/diagnose/feedback'),
        headers: headers,
        body: jsonEncode({'scan_id': scanId, 'was_correct': wasCorrect, 'correct_disease': correctDisease}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
