import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/provider_models.dart';
import '../api_client.dart';

class AgronomistService {
  static Future<List<Agronomist>> listAgronomists({
    String? county,
    String? specialization,
    bool? verified,
  }) async {
    try {
      final res = await ApiClient.get(
        '/agronomists',
        queryParameters: {
          if (county != null) 'county': county,
          if (specialization != null) 'specialization': specialization,
          if (verified != null) 'verified': verified.toString(),
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['agronomists'] != null) {
          return (data['agronomists'] as List)
              .map((e) => Agronomist.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('listAgronomists error: $e');
    }
    return [];
  }

  static Future<List<Agronomist>> getNearbyAgronomists({
    required double lat,
    required double lng,
    double radius = 50,
  }) async {
    try {
      final res = await ApiClient.get(
        '/agronomists/nearby',
        queryParameters: {
          'lat': lat.toString(),
          'lng': lng.toString(),
          'radius': radius.toString(),
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['agronomists'] != null) {
          return (data['agronomists'] as List)
              .map((e) => Agronomist.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('getNearbyAgronomists error: $e');
    }
    return [];
  }

  static Future<Agronomist?> getAgronomist(int id) async {
    try {
      final res = await ApiClient.get('/agronomists/$id');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['agronomist'] != null) {
          return Agronomist.fromJson(data['agronomist'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('getAgronomist error: $e');
    }
    return null;
  }

  static Future<bool> requestConsultation(int agronomistId, {String? message, String? scanId, String? consultationType}) async {
    try {
      final res = await ApiClient.post(
        '/agronomists/$agronomistId/consult',
        requiresAuth: true,
        body: jsonEncode({
          if (message != null) 'farmer_message': message,
          if (scanId != null) 'scan_id': scanId,
          if (consultationType != null) 'consultation_type': consultationType,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('requestConsultation error: $e');
    }
    return false;
  }
}
