import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/communication_models.dart';
import '../api_client.dart';

class NotificationService {
  static Future<List<Notification>> listNotifications({bool? unreadOnly, String? type}) async {
    try {
      final res = await ApiClient.get(
        '/notifications',
        requiresAuth: true,
        queryParameters: {
          if (unreadOnly != null && unreadOnly) 'unread_only': 'true',
          if (type != null) 'type': type,
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['notifications'] != null) {
          return (data['notifications'] as List)
              .map((e) => Notification.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('listNotifications error: $e');
    }
    return [];
  }

  static Future<bool> markAsRead(int notificationId) async {
    try {
      final res = await ApiClient.put(
        '/notifications/$notificationId/read',
        requiresAuth: true,
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
    return false;
  }

  static Future<bool> markAllAsRead() async {
    try {
      final res = await ApiClient.put(
        '/notifications/read-all',
        requiresAuth: true,
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('markAllAsRead error: $e');
    }
    return false;
  }
}
