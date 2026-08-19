import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../api_client.dart';

class AdminService {
  static Future<List<Map<String, dynamic>>> listVerificationRequests({String? status, String? requesterType}) async {
    try {
      final res = await ApiClient.get(
        '/admin/verifications',
        requiresAuth: true,
        queryParameters: {
          if (status != null) 'status': status,
          if (requesterType != null) 'requester_type': requesterType,
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['requests'] != null) {
          return List<Map<String, dynamic>>.from(data['requests'] as List);
        }
      }
    } catch (e) {
      debugPrint('listVerificationRequests error: $e');
    }
    return [];
  }

  static Future<bool> reviewVerification(int requestId, String status, {String? reviewNotes}) async {
    try {
      final res = await ApiClient.put(
        '/admin/verifications/$requestId',
        requiresAuth: true,
        body: jsonEncode({
          'status': status,
          if (reviewNotes != null) 'review_notes': reviewNotes,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('reviewVerification error: $e');
    }
    return false;
  }

  static Future<List<Map<String, dynamic>>> listUsers({String? role, String? county}) async {
    try {
      final res = await ApiClient.get(
        '/admin/users',
        requiresAuth: true,
        queryParameters: {
          if (role != null) 'role': role,
          if (county != null) 'county': county,
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['users'] != null) {
          return List<Map<String, dynamic>>.from(data['users'] as List);
        }
      }
    } catch (e) {
      debugPrint('listUsers error: $e');
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getScanReports({int days = 30, String? county, String? cropType}) async {
    try {
      final res = await ApiClient.get(
        '/admin/reports/scans',
        requiresAuth: true,
        queryParameters: {
          'days': days.toString(),
          if (county != null) 'county': county,
          if (cropType != null) 'crop_type': cropType,
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['reports'] != null) {
          return List<Map<String, dynamic>>.from(data['reports'] as List);
        }
      }
    } catch (e) {
      debugPrint('getScanReports error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getProviderReports() async {
    try {
      final res = await ApiClient.get('/admin/reports/providers', requiresAuth: true);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data;
        }
      }
    } catch (e) {
      debugPrint('getProviderReports error: $e');
    }
    return null;
  }
}
