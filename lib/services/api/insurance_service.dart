import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/insurance_models.dart';
import '../api_client.dart';

class InsuranceService {
  static Future<List<InsuranceProvider>> listProviders({String? county, bool? verified}) async {
    try {
      final res = await ApiClient.get(
        '/insurance/providers',
        queryParameters: {
          if (county != null) 'county': county,
          if (verified != null) 'verified': verified.toString(),
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['providers'] != null) {
          return (data['providers'] as List)
              .map((e) => InsuranceProvider.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('listProviders error: $e');
    }
    return [];
  }

  static Future<List<InsuranceProvider>> getNearbyProviders({
    required double lat,
    required double lng,
    double radius = 50,
  }) async {
    try {
      final res = await ApiClient.get(
        '/insurance/providers/nearby',
        queryParameters: {
          'lat': lat.toString(),
          'lng': lng.toString(),
          'radius': radius.toString(),
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['providers'] != null) {
          return (data['providers'] as List)
              .map((e) => InsuranceProvider.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('getNearbyProviders error: $e');
    }
    return [];
  }

  static Future<InsuranceProvider?> getProvider(int id) async {
    try {
      final res = await ApiClient.get('/insurance/providers/$id');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['provider'] != null) {
          return InsuranceProvider.fromJson(data['provider'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('getProvider error: $e');
    }
    return null;
  }

  static Future<List<InsuranceProduct>> getProducts(int providerId) async {
    try {
      final res = await ApiClient.get('/insurance/providers/$providerId/products');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['products'] != null) {
          return (data['products'] as List)
              .map((e) => InsuranceProduct.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('getProducts error: $e');
    }
    return [];
  }

  static Future<bool> submitInquiry(int providerId, {String? message, int? productId, String? cropType, double? farmSizeHectares}) async {
    try {
      final res = await ApiClient.post(
        '/insurance/providers/$providerId/inquire',
        requiresAuth: true,
        body: jsonEncode({
          if (message != null) 'message': message,
          if (productId != null) 'product_id': productId,
          if (cropType != null) 'crop_type': cropType,
          if (farmSizeHectares != null) 'farm_size_hectares': farmSizeHectares,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('submitInquiry error: $e');
    }
    return false;
  }
}
