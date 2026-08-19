import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/search_models.dart';
import '../../models/ecosystem_models.dart';
import '../api_client.dart';

class SearchService {
  static Future<List<SearchResult>> searchServices({
    required String query,
    String? type,
    String? county,
    double? lat,
    double? lng,
    double? radius,
    bool? verified,
  }) async {
    try {
      final res = await ApiClient.get(
        '/search/services',
        queryParameters: {
          'q': query,
          if (type != null) 'type': type,
          if (county != null) 'county': county,
          if (lat != null) 'lat': lat.toString(),
          if (lng != null) 'lng': lng.toString(),
          if (radius != null) 'radius': radius.toString(),
          if (verified != null) 'verified': verified.toString(),
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['results'] != null) {
          return (data['results'] as List)
              .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('searchServices error: $e');
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> searchDiseases({required String query, String? cropType}) async {
    try {
      final res = await ApiClient.get(
        '/search/diseases',
        queryParameters: {
          'q': query,
          if (cropType != null) 'crop_type': cropType,
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['diseases'] != null) {
          return List<Map<String, dynamic>>.from(data['diseases'] as List);
        }
      }
    } catch (e) {
      debugPrint('searchDiseases error: $e');
    }
    return [];
  }

  static Future<List<String>> searchCrops() async {
    try {
      final res = await ApiClient.get('/search/crops');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['crops'] != null) {
          return List<String>.from(data['crops'] as List);
        }
      }
    } catch (e) {
      debugPrint('searchCrops error: $e');
    }
    return [];
  }

  static Future<List<AgriculturalEvent>> searchEvents({
    required String query,
    String? county,
    String? eventType,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final res = await ApiClient.get(
        '/search/events',
        queryParameters: {
          'q': query,
          if (county != null) 'county': county,
          if (eventType != null) 'event_type': eventType,
          if (fromDate != null) 'from_date': fromDate.toIso8601String(),
          if (toDate != null) 'to_date': toDate.toIso8601String(),
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['events'] != null) {
          return (data['events'] as List)
              .map((e) => AgriculturalEvent.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('searchEvents error: $e');
    }
    return [];
  }
}
