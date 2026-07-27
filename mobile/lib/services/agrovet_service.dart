import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shambadoc/services/agrovet_cache_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class Agrovet {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> products;
  final bool isVerified;
  final bool isSponsored;
  final bool isActive;
  final double? distanceKm;

  Agrovet({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.products,
    required this.isVerified,
    required this.isSponsored,
    required this.isActive,
    this.distanceKm,
  });

  factory Agrovet.fromJson(Map<String, dynamic> json) {
    return Agrovet(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      name: json['name'] ?? json['Name'] ?? 'Unknown Agrovet',
      phone: json['phone'] ?? json['Phone'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      address: json['address'] ?? json['Address'] ?? '',
      latitude: (json['latitude'] ?? json['Latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['Longitude'] ?? 0.0).toDouble(),
      products: json['products'] != null
          ? List<String>.from(json['products'])
          : json['Products'] != null
              ? List<String>.from(json['Products'])
              : [],
      isVerified: json['is_verified'] ?? json['IsVerified'] ?? false,
      isSponsored: json['is_sponsored'] ?? json['IsSponsored'] ?? false,
      isActive: json['is_active'] ?? json['IsActive'] ?? true,
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : json['DistanceKm'] != null
              ? (json['DistanceKm'] as num).toDouble()
              : null,
    );
  }

  Agrovet copyWith({double? distanceKm}) {
    return Agrovet(
      id: id,
      name: name,
      phone: phone,
      email: email,
      address: address,
      latitude: latitude,
      longitude: longitude,
      products: products,
      isVerified: isVerified,
      isSponsored: isSponsored,
      isActive: isActive,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}

class AgrovetService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<List<Agrovet>> findNearbyAgrovets({
    double? lat,
    double? lng,
    double radiusKm = 50,
  }) async {
    try {
      const baseUrl = String.fromEnvironment(
        'SHAMBADOC_API_URL',
        defaultValue: 'http://192.168.8.5:3000',
      );
      final uri = Uri.parse('$baseUrl/agrovets/nearby').replace(queryParameters: {
        if (lat != null) 'lat': lat.toString(),
        if (lng != null) 'lng': lng.toString(),
        'radius': radiusKm.toString(),
      });

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body) as List;
        return data.map((e) => Agrovet.fromJson(e)).toList();
      }
      return <Agrovet>[];
    } catch (e) {
      return <Agrovet>[];
    }
  }

  Future<List<Agrovet>> findNearbyAgrovetsWithFallback({
    required Position userPosition,
    double radiusKm = 25,
  }) async {
    final cache = AgrovetCacheService();
    final connectivity = await Connectivity().checkConnectivity();

    if (connectivity != ConnectivityResult.none) {
      try {
        final agrovets = await findNearbyAgrovets(
          lat: userPosition.latitude,
          lng: userPosition.longitude,
          radiusKm: radiusKm,
        );

        if (agrovets.isNotEmpty) {
          await cache.cacheAgrovets(agrovets);
          return agrovets;
        }
      } catch (e) {
        // fall through to cache
      }
    }

    final cached = await cache.getCachedAgrovets();
    if (cached.isEmpty) {
      return getLocalFallbackAgrovets();
    }

    return cached.where((a) {
      final distance = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            a.latitude,
            a.longitude,
          ) /
          1000;
      return distance <= radiusKm;
    }).toList();
  }

  Future<List<Agrovet>> getLocalFallbackAgrovets() async {
    return [
      Agrovet(
        id: '1',
        name: 'Kisumu Agrovet',
        phone: '+254712345678',
        email: 'info@kisumuagrovet.co.ke',
        address: 'Kisumu, Kenya',
        latitude: -0.1022,
        longitude: 34.7617,
        products: ['Seeds', 'Fertilizer', 'Pesticides'],
        isVerified: true,
        isSponsored: true,
        isActive: true,
      ),
      Agrovet(
        id: '2',
        name: 'Nakuru Farm Inputs',
        phone: '+254723456789',
        email: 'info@nakurufarm.co.ke',
        address: 'Nakuru, Kenya',
        latitude: -0.3031,
        longitude: 36.0663,
        products: ['Seeds', 'Chemicals', 'Tools'],
        isVerified: true,
        isSponsored: false,
        isActive: true,
      ),
      Agrovet(
        id: '3',
        name: 'Eldoret Seeds & Chemicals',
        phone: '+254734567890',
        email: 'info@eldoretseeds.co.ke',
        address: 'Eldoret, Kenya',
        latitude: 0.5143,
        longitude: 35.2698,
        products: ['Seeds', 'Herbicides', 'Fungicides'],
        isVerified: false,
        isSponsored: true,
        isActive: true,
      ),
    ];
  }
}
