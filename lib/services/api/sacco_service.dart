import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/sacco_models.dart';
import '../api_client.dart';

class SaccoService {
  static Future<List<Sacco>> listSaccos({String? county, bool? verified}) async {
    try {
      final res = await ApiClient.get(
        '/saccos',
        queryParameters: {
          if (county != null) 'county': county,
          if (verified != null) 'verified': verified.toString(),
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['saccos'] != null) {
          return (data['saccos'] as List)
              .map((e) => Sacco.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('listSaccos error: $e');
    }
    return [];
  }

  static Future<List<Sacco>> getNearbySaccos({
    required double lat,
    required double lng,
    double radius = 50,
  }) async {
    try {
      final res = await ApiClient.get(
        '/saccos/nearby',
        queryParameters: {
          'lat': lat.toString(),
          'lng': lng.toString(),
          'radius': radius.toString(),
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['saccos'] != null) {
          return (data['saccos'] as List)
              .map((e) => Sacco.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('getNearbySaccos error: $e');
    }
    return [];
  }

  static Future<Sacco?> getSacco(int id) async {
    try {
      final res = await ApiClient.get('/saccos/$id');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['sacco'] != null) {
          return Sacco.fromJson(data['sacco'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('getSacco error: $e');
    }
    return null;
  }

  static Future<List<FinancialProduct>> getFinancialProducts(int saccoId) async {
    try {
      final res = await ApiClient.get('/saccos/$saccoId/products');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['products'] != null) {
          return (data['products'] as List)
              .map((e) => FinancialProduct.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('getFinancialProducts error: $e');
    }
    return [];
  }

  static Future<bool> submitInquiry(int saccoId, {String? message, int? productId}) async {
    try {
      final res = await ApiClient.post(
        '/saccos/$saccoId/inquire',
        requiresAuth: true,
        body: jsonEncode({
          if (message != null) 'message': message,
          if (productId != null) 'product_id': productId,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('submitInquiry error: $e');
    }
    return false;
  }
}
