import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shambadoc/services/api_service.dart';

class AgroDealerMap extends StatefulWidget {
  const AgroDealerMap({super.key});

  @override
  State<AgroDealerMap> createState() => _AgroDealerMapState();
}

class _AgroDealerMapState extends State<AgroDealerMap> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  bool _isLoading = true;

  static const LatLng _defaultLocation = LatLng(-1.2921, 36.8219);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { setState(() => _isLoading = false); return; }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) { setState(() => _isLoading = false); return; }

      _currentPosition = await Geolocator.getCurrentPosition();
      await _loadDealers();
    } catch (e) {
      print('Location error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDealers() async {
    final data = await ApiService.getDealers(
      lat: _currentPosition?.latitude,
      lng: _currentPosition?.longitude,
      radius: 50,
    );

    if (data != null && data['dealers'] != null) {
      final dealers = data['dealers'] as List;
      setState(() {
        _markers.clear();
        for (var dealer in dealers) {
          final lat = dealer['latitude'] as double?;
          final lng = dealer['longitude'] as double?;
          if (lat != null && lng != null) {
            _markers.add(Marker(
              markerId: MarkerId(dealer['id'] ?? 'unknown'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: dealer['name'] ?? 'Agro-Dealer',
                snippet: dealer['phone'] ?? 'Tap to call',
                onTap: () => _callDealer(dealer['phone']),
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ));
          }
        }
      });
    }

    if (_markers.isEmpty) _addDemoMarkers();
  }

  void _addDemoMarkers() {
    final demoDealers = [
      {'name': 'Kisumu Agrovet', 'lat': -0.1022, 'lng': 34.7617, 'phone': '+254712345678'},
      {'name': 'Nakuru Farm Inputs', 'lat': -0.3031, 'lng': 36.0663, 'phone': '+254723456789'},
      {'name': 'Eldoret Seeds & Chemicals', 'lat': 0.5143, 'lng': 35.2698, 'phone': '+254734567890'},
    ];

    for (var dealer in demoDealers) {
      _markers.add(Marker(
        markerId: MarkerId(dealer['name']!),
        position: LatLng(dealer['lat']! as double, dealer['lng']! as double),
        infoWindow: InfoWindow(
          title: dealer['name'] as String,
          snippet: 'Tap to call',
          onTap: () => _callDealer(dealer['phone'] as String?),
        ),
      ));
    }
  }

  Future<void> _callDealer(String? phone) async {
    if (phone == null) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _defaultLocation;

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Agro-Dealers')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(target: initialPosition, zoom: 12),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              onMapCreated: (controller) => _mapController = controller,
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _mapController?.animateCamera(CameraUpdate.newLatLng(initialPosition));
        },
        label: const Text('My Location'),
        icon: const Icon(Icons.my_location),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
