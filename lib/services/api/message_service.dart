import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/communication_models.dart';
import '../api_client.dart';

class MessageService {
  static Future<List<Map<String, dynamic>>> listConversations() async {
    try {
      final res = await ApiClient.get('/messages/conversations', requiresAuth: true);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['conversations'] != null) {
          return List<Map<String, dynamic>>.from(data['conversations'] as List);
        }
      }
    } catch (e) {
      debugPrint('listConversations error: $e');
    }
    return [];
  }

  static Future<List<Message>> getConversation(String otherUserId) async {
    try {
      final res = await ApiClient.get('/messages/conversations/$otherUserId', requiresAuth: true);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['messages'] != null) {
          return (data['messages'] as List)
              .map((e) => Message.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('getConversation error: $e');
    }
    return [];
  }

  static Future<Message?> sendMessage(String receiverId, String content, {String? consultationId, String? messageType}) async {
    try {
      final res = await ApiClient.post(
        '/messages/send',
        requiresAuth: true,
        body: jsonEncode({
          'receiver_id': receiverId,
          'content': content,
          if (consultationId != null) 'consultation_id': consultationId,
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
      debugPrint('sendMessage error: $e');
    }
    return null;
  }
}
