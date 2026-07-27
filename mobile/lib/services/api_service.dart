import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'SHAMBADOC_API_URL',
    defaultValue: 'http://192.168.8.5:3000/api',
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
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('API Error (getDealers): $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> logDiagnosis(Map<String, dynamic> scanData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/diagnose/log'),
        headers: headers,
        body: jsonEncode(scanData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('API Error (logDiagnosis): $e');
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
      print('API Error (submitFeedback): $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/diagnose/stats'), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('API Error (getStats): $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getHeatmap({String? crop, int days = 30}) async {
    try {
      final uri = Uri.parse('$baseUrl/diagnose/heatmap').replace(queryParameters: {
        if (crop != null) 'crop': crop,
        'days': days.toString(),
      });
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('API Error (getHeatmap): $e');
      return null;
    }
  }
}
