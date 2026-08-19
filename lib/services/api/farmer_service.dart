import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/farmer_models.dart';
import '../api_client.dart';

class FarmerService {
  static Future<FarmerProfile?> getProfile() async {
    try {
      final res = await ApiClient.get('/farmers/profile', requiresAuth: true);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['profile'] != null) {
          return FarmerProfile.fromJson(data['profile'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('getProfile error: $e');
    }
    return null;
  }

  static Future<FarmerProfile?> upsertProfile({
    required String fullName,
    required String county,
    String? subCounty,
    String? ward,
    double? farmSizeHectares,
    List<String> primaryCrops = const [],
    int? farmingExperienceYears,
    String? phoneNumber,
    String? profilePhotoUrl,
  }) async {
    try {
      final res = await ApiClient.put(
        '/farmers/profile',
        requiresAuth: true,
        body: jsonEncode({
          'full_name': fullName,
          'county': county,
          if (subCounty != null) 'sub_county': subCounty,
          if (ward != null) 'ward': ward,
          if (farmSizeHectares != null) 'farm_size_hectares': farmSizeHectares,
          'primary_crops': primaryCrops,
          if (farmingExperienceYears != null) 'farming_experience_years': farmingExperienceYears,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['profile'] != null) {
          return FarmerProfile.fromJson(data['profile'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('upsertProfile error: $e');
    }
    return null;
  }

  static Future<List<Farm>> getFarms() async {
    try {
      final res = await ApiClient.get('/farmers/farms', requiresAuth: true);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['farms'] != null) {
          return (data['farms'] as List)
              .map((e) => Farm.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('getFarms error: $e');
    }
    return [];
  }

  static Future<Farm?> createFarm({
    required String name,
    required String cropType,
    required String county,
    double? latitude,
    double? longitude,
    double? areaHectares,
    DateTime? plantedAt,
    String? notes,
  }) async {
    try {
      final res = await ApiClient.post(
        '/farmers/farms',
        requiresAuth: true,
        body: jsonEncode({
          'name': name,
          'crop_type': cropType,
          'county': county,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (areaHectares != null) 'area_hectares': areaHectares,
          if (plantedAt != null) 'planted_at': plantedAt.toIso8601String(),
          if (notes != null) 'notes': notes,
        }),
      );

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['farm'] != null) {
          return Farm.fromJson(data['farm'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('createFarm error: $e');
    }
    return null;
  }

  static Future<FarmerDashboard?> getDashboard() async {
    try {
      final res = await ApiClient.get('/farmers/dashboard', requiresAuth: true);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return FarmerDashboard.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('getDashboard error: $e');
    }
    return null;
  }
}

class FarmerDashboard {
  final FarmerProfile? profile;
  final List<Farm> farms;
  final List<dynamic> recentScans;

  FarmerDashboard({
    this.profile,
    this.farms = const [],
    this.recentScans = const [],
  });

  factory FarmerDashboard.fromJson(Map<String, dynamic> json) {
    return FarmerDashboard(
      profile: json['profile'] != null ? FarmerProfile.fromJson(json['profile'] as Map<String, dynamic>) : null,
      farms: json['farms'] != null ? (json['farms'] as List).map((e) => Farm.fromJson(e as Map<String, dynamic>)).toList() : [],
      recentScans: json['recentScans'] != null ? List<dynamic>.from(json['recentScans']) : [],
    );
  }
}
