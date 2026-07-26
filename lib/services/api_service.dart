import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'SHAMBADOC_API_URL',
    defaultValue: 'http://10.0.2.2:3000/api', // 10.0.2.2 = localhost from Android emulator
  );
  static const Map<String, String> _headers = {'Content-Type': 'application/json'};
  static const _timeout = Duration(seconds: 10);

  // ── Dealers ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getDealers({
    double? lat, double? lng, double radius = 50,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/dealers').replace(queryParameters: {
        if (lat != null) 'lat': lat.toString(),
        if (lng != null) 'lng': lng.toString(),
        'radius': radius.toString(),
      });
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      _log('getDealers error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getDealerById(String id) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/dealers/$id'), headers: _headers)
          .timeout(_timeout);
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      _log('getDealerById error: $e');
    }
    return null;
  }

  // ── Diagnose ───────────────────────────────────────────────────────────────

  static Future<bool> logScan(Map<String, dynamic> data) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/diagnose/log'),
              headers: _headers, body: jsonEncode(data))
          .timeout(_timeout);
      return res.statusCode == 201 || res.statusCode == 200;
    } catch (e) {
      _log('logScan error: $e');
      return false;
    }
  }

  static Future<bool> submitFeedback({
    required String scanId,
    required bool wasCorrect,
    String? correctDisease,
  }) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/diagnose/feedback'),
              headers: _headers,
              body: jsonEncode({
                'scan_id': scanId,
                'was_correct': wasCorrect,
                if (correctDisease != null) 'correct_disease': correctDisease,
              }))
          .timeout(_timeout);
      return res.statusCode == 201 || res.statusCode == 200;
    } catch (e) {
      _log('submitFeedback error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getRegionalStats({
    String? county, int days = 30,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/diagnose/stats').replace(queryParameters: {
        if (county != null) 'county': county,
        'days': days.toString(),
      });
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      _log('getRegionalStats error: $e');
    }
    return null;
  }

  // ── Health check ───────────────────────────────────────────────────────────

  static Future<bool> isBackendReachable() async {
    try {
      final res = await http
          .get(Uri.parse(baseUrl.replaceAll('/api', '/health')))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static void _log(String msg) => print('[ApiService] $msg');
}
