import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

class ApiService {
  static Future<Map<String, dynamic>?> getDealers({
    double? lat, double? lng, double radius = 50,
  }) async {
    try {
      final res = await ApiClient.get(
        '/dealers',
        queryParameters: {
          if (lat != null) 'lat': lat.toString(),
          if (lng != null) 'lng': lng.toString(),
          'radius': radius.toString(),
        },
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      _log('getDealers error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getDealerById(String id) async {
    try {
      final res = await ApiClient.get('/dealers/$id');
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      _log('getDealerById error: $e');
    }
    return null;
  }

  static Future<bool> logScan(Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.post(
        '/diagnose/log',
        body: jsonEncode(data),
      );
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
      final res = await ApiClient.post(
        '/diagnose/feedback',
        body: jsonEncode({
          'scan_id': scanId,
          'was_correct': wasCorrect,
          if (correctDisease != null) 'correct_disease': correctDisease,
        }),
      );
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
      final res = await ApiClient.get(
        '/diagnose/stats',
        queryParameters: {
          if (county != null) 'county': county,
          'days': days.toString(),
        },
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      _log('getRegionalStats error: $e');
    }
    return null;
  }

  static Future<bool> isBackendReachable() async {
    try {
      final healthUrl = ApiClient.baseUrl.replaceAll('/api', '/health');
      final res = await http.get(Uri.parse(healthUrl)).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static void _log(String msg) => debugPrint('[ApiService] $msg');
}
