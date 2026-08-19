import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/provider_models.dart';
import '../../models/ecosystem_models.dart';
import '../api_client.dart';

class GovernmentService {
  static Future<List<GovernmentOfficer>> listOfficers({String? county}) async {
    try {
      final res = await ApiClient.get(
        '/government/officers',
        queryParameters: {
          if (county != null) 'county': county,
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['officers'] != null) {
          return (data['officers'] as List)
              .map((e) => GovernmentOfficer.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('listOfficers error: $e');
    }
    return [];
  }

  static Future<List<GovernmentOfficer>> getNearbyOfficers({
    required double lat,
    required double lng,
    double radius = 50,
  }) async {
    try {
      final res = await ApiClient.get(
        '/government/officers/nearby',
        queryParameters: {
          'lat': lat.toString(),
          'lng': lng.toString(),
          'radius': radius.toString(),
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['officers'] != null) {
          return (data['officers'] as List)
              .map((e) => GovernmentOfficer.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('getNearbyOfficers error: $e');
    }
    return [];
  }

  static Future<List<Advisory>> getAdvisories({String? county, String? cropType}) async {
    try {
      final res = await ApiClient.get(
        '/government/advisories',
        queryParameters: {
          if (county != null) 'county': county,
          if (cropType != null) 'crop_type': cropType,
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['advisories'] != null) {
          return (data['advisories'] as List)
              .map((e) => Advisory.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('getAdvisories error: $e');
    }
    return [];
  }

  static Future<List<GovernmentProgram>> getPrograms() async {
    try {
      final res = await ApiClient.get('/government/programs');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['programs'] != null) {
          return (data['programs'] as List)
              .map((e) => GovernmentProgram.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('getPrograms error: $e');
    }
    return [];
  }

  static Future<List<AgriculturalEvent>> getEvents({String? county}) async {
    try {
      final res = await ApiClient.get(
        '/government/events',
        queryParameters: {
          if (county != null) 'county': county,
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
      debugPrint('getEvents error: $e');
    }
    return [];
  }
}
