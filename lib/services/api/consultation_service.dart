import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/communication_models.dart';
import '../api_client.dart';

class ConsultationService {
  static Future<List<Consultation>> listConsultations({String? status, String? type}) async {
    try {
      final res = await ApiClient.get(
        '/consultations',
        requiresAuth: true,
        queryParameters: {
          if (status != null) 'status': status,
          if (type != null) 'type': type,
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['consultations'] != null) {
          return (data['consultations'] as List)
              .map((e) => Consultation.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('listConsultations error: $e');
    }
    return [];
  }

  static Future<Consultation?> getConsultation(int id) async {
    try {
      final res = await ApiClient.get('/consultations/$id', requiresAuth: true);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['consultation'] != null) {
          return Consultation.fromJson(data['consultation'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('getConsultation error: $e');
    }
    return null;
  }

  static Future<Consultation?> createConsultation({
    String? agronomistId,
    String? governmentOfficerId,
    String consultationType = 'chat',
    String? farmerMessage,
    String? scanId,
    DateTime? scheduledAt,
  }) async {
    try {
      final res = await ApiClient.post(
        '/consultations',
        requiresAuth: true,
        body: jsonEncode({
          if (agronomistId != null) 'agronomist_id': agronomistId,
          if (governmentOfficerId != null) 'government_officer_id': governmentOfficerId,
          'consultation_type': consultationType,
          if (farmerMessage != null) 'farmer_message': farmerMessage,
          if (scanId != null) 'scan_id': scanId,
          if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
        }),
      );
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['consultation'] != null) {
          return Consultation.fromJson(data['consultation'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('createConsultation error: $e');
    }
    return null;
  }

  static Future<bool> updateStatus(int consultationId, String status) async {
    try {
      final res = await ApiClient.put(
        '/consultations/$consultationId/status',
        requiresAuth: true,
        body: jsonEncode({'status': status}),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('updateStatus error: $e');
    }
    return false;
  }

  static Future<Message?> addMessage(int consultationId, String content, {String? receiverId, String? messageType}) async {
    try {
      final res = await ApiClient.post(
        '/consultations/$consultationId/message',
        requiresAuth: true,
        body: jsonEncode({
          'content': content,
          if (receiverId != null) 'receiver_id': receiverId,
          if (messageType != null) 'message_type': messageType,
        }),
      );
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['message'] != null) {
          return Message.fromJson(data['message'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('addMessage error: $e');
    }
    return null;
  }
}
