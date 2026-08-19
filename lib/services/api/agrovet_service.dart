import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/agrovet_models.dart';
import '../api_client.dart';

class AgrovetService {
  static Future<List<Agrovet>> listAgrovets({
    String? county,
    bool? verified,
    String? productCategory,
  }) async {
    try {
      final res = await ApiClient.get(
        '/agrovets',
        queryParameters: {
          if (county != null) 'county': county,
          if (verified != null) 'verified': verified.toString(),
          if (productCategory != null) 'product_category': productCategory,
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['agrovets'] != null) {
          return (data['agrovets'] as List)
              .map((e) => Agrovet.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('listAgrovets error: $e');
    }
    return [];
  }

  static Future<List<Agrovet>> getNearbyAgrovets({
    required double lat,
    required double lng,
    double radius = 50,
  }) async {
    try {
      final res = await ApiClient.get(
        '/agrovets/nearby',
        queryParameters: {
          'lat': lat.toString(),
          'lng': lng.toString(),
          'radius': radius.toString(),
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['agrovets'] != null) {
          return (data['agrovets'] as List)
              .map((e) => Agrovet.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('getNearbyAgrovets error: $e');
    }
    return [];
  }

  static Future<Agrovet?> getAgrovet(int id) async {
    try {
      final res = await ApiClient.get('/agrovets/$id');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['agrovet'] != null) {
          return Agrovet.fromJson(data['agrovet'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('getAgrovet error: $e');
    }
    return null;
  }

  static Future<List<AgrovetProduct>> getProducts(int agrovetId, {String? category, String? search}) async {
    try {
      final res = await ApiClient.get(
        '/agrovets/$agrovetId/products',
        queryParameters: {
          if (category != null) 'category': category,
          if (search != null) 'search': search,
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['products'] != null) {
          return (data['products'] as List)
              .map((e) => AgrovetProduct.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('getProducts error: $e');
    }
    return [];
  }

  static Future<bool> submitInquiry(int agrovetId, {String? message, int? productId, int? quantity}) async {
    try {
      final res = await ApiClient.post(
        '/agrovets/$agrovetId/inquire',
        requiresAuth: true,
        body: jsonEncode({
          if (message != null) 'message': message,
          if (productId != null) 'product_id': productId,
          if (quantity != null) 'quantity': quantity,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('submitInquiry error: $e');
    }
    return false;
  }
}
