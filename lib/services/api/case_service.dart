import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/case_models.dart';
import '../api_client.dart';

class CaseService {
  static Future<List<DiseaseCase>> listCases({String? status, bool? myCases}) async {
    try {
      final res = await ApiClient.get(
        '/cases',
        requiresAuth: true,
        queryParameters: {
          if (status != null) 'status': status,
          if (myCases != null && myCases) 'my_cases': 'true',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['cases'] != null) {
          return (data['cases'] as List)
              .map((e) => DiseaseCase.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('listCases error: $e');
    }
    return [];
  }

  static Future<DiseaseCase?> getCase(int id) async {
    try {
      final res = await ApiClient.get('/cases/$id', requiresAuth: true);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['case'] != null) {
          return DiseaseCase.fromJson(data['case'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('getCase error: $e');
    }
    return null;
  }

  static Future<DiseaseCase?> createCase({
    String? scanId,
    String? farmerNote,
    String? cropType,
    String? diseaseName,
    String? county,
  }) async {
    try {
      final res = await ApiClient.post(
        '/cases',
        requiresAuth: true,
        body: jsonEncode({
          if (scanId != null) 'scan_id': scanId,
          if (farmerNote != null) 'farmer_note': farmerNote,
          if (cropType != null) 'crop_type': cropType,
          if (diseaseName != null) 'disease_name': diseaseName,
          if (county != null) 'county': county,
        }),
      );
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['case'] != null) {
          return DiseaseCase.fromJson(data['case'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('createCase error: $e');
    }
    return null;
  }

  static Future<bool> assignCase(int caseId, String assignedTo) async {
    try {
      final res = await ApiClient.put(
        '/cases/$caseId/assign',
        requiresAuth: true,
        body: jsonEncode({'assigned_to': assignedTo}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('assignCase error: $e');
    }
    return false;
  }

  static Future<bool> resolveCase(int caseId, {String? agronomistDiagnosis, String? agronomistAdvice}) async {
    try {
      final res = await ApiClient.put(
        '/cases/$caseId/resolve',
        requiresAuth: true,
        body: jsonEncode({
          if (agronomistDiagnosis != null) 'agronomist_diagnosis': agronomistDiagnosis,
          if (agronomistAdvice != null) 'agronomist_advice': agronomistAdvice,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('resolveCase error: $e');
    }
    return false;
  }

  static Future<bool> escalateCase(int caseId, String note) async {
    try {
      final res = await ApiClient.post(
        '/cases/$caseId/escalate',
        requiresAuth: true,
        body: jsonEncode({'note': note}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('escalateCase error: $e');
    }
    return false;
  }
}
