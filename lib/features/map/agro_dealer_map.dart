import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shambadoc/app/theme.dart';
import 'package:shambadoc/services/api_service.dart';

class AgroDealerMap extends StatefulWidget {
  final bool embedded;
  const AgroDealerMap({super.key, this.embedded = false});
  @override
  State<AgroDealerMap> createState() => _AgroDealerMapState();
}

class _AgroDealerMapState extends State<AgroDealerMap> {
  GoogleMapController? _mapCtrl;
  Position? _position;
  final Set<Marker> _markers = {};
  List<Map<String, dynamic>> _dealers = [];
  bool _loading = true;
  String? _error;

  static const _default = LatLng(-1.2921, 36.8219); // Nairobi

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() { _loading = true; _error = null; });
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw Exception('Location services are disabled.');

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied.');
      }

      _position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium)
          .timeout(const Duration(seconds: 8));

      await _loadDealers();
    } catch (e) {
      setState(() => _error = e.toString());
      _addDemoMarkers();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDealers() async {
    final data = await ApiService.getDealers(
      lat: _position?.latitude,
      lng: _position?.longitude,
      radius: 50,
    );

    if (data != null && data['dealers'] != null) {
      final list = (data['dealers'] as List)
          .cast<Map<String, dynamic>>();
      _dealers = list;
      _buildMarkers(list);
    } else {
      _addDemoMarkers();
    }
  }

  void _buildMarkers(List<Map<String, dynamic>> dealers) {
    setState(() {
      _markers.clear();
      for (final d in dealers) {
        final lat = (d['latitude'] as num?)?.toDouble();
        final lng = (d['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        _markers.add(Marker(
          markerId: MarkerId(d['id']?.toString() ?? d['name']),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              d['is_sponsored'] == true
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: d['name']),
          onTap: () => _showDealerSheet(d),
        ));
      }
    });
  }

  void _addDemoMarkers() {
    final demo = [
      {'id': '1', 'name': 'Kisumu Agrovet', 'latitude': -0.1022, 'longitude': 34.7617,
        'phone': '+254712345678', 'address': 'Oginga Odinga St, Kisumu',
        'products': ['Fungicides', 'Seeds', 'Fertilizers'], 'is_verified': true,
        'distance_km': 12.4},
      {'id': '2', 'name': 'Nakuru Farm Inputs', 'latitude': -0.3031, 'longitude': 36.0663,
        'phone': '+254723456789', 'address': 'Nakuru Town Centre',
        'products': ['Herbicides', 'Pesticides', 'Tools'], 'is_verified': true,
        'distance_km': 34.1},
      {'id': '3', 'name': 'Eldoret Seeds & Chemicals', 'latitude': 0.5143, 'longitude': 35.2698,
        'phone': '+254734567890', 'address': 'Eldoret CBD',
        'products': ['Seeds', 'Fertilizers', 'Sprayers'], 'is_verified': false,
        'distance_km': 56.8},
      {'id': '4', 'name': 'Nairobi Agro Centre', 'latitude': -1.2921, 'longitude': 36.8219,
        'phone': '+254756789012', 'address': 'Industrial Area, Nairobi',
        'products': ['Seeds', 'Fungicides', 'PPE'], 'is_verified': true,
        'distance_km': 2.1},
    ];
    _dealers = demo;
    _buildMarkers(demo);
  }

  void _showDealerSheet(Map<String, dynamic> dealer) {
    final products = (dealer['products'] as List?)?.cast<String>() ?? [];
    final isVerified = dealer['is_verified'] == true;
    final dist = dealer['distance_km'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),

          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle),
              child: const Icon(Icons.store_rounded,
                  color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(dealer['name'] ?? 'Agro-Dealer',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded,
                        color: AppColors.info, size: 16),
                  ],
                ]),
                if (dist != null)
                  Text('${dist is double ? dist.toStringAsFixed(1) : dist} km away',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            )),
          ]),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Address
          if (dealer['address'] != null)
            _InfoRow(
              icon: Icons.location_on_outlined,
              text: dealer['address'],
            ),

          // Phone
          if (dealer['phone'] != null)
            _InfoRow(
              icon: Icons.phone_outlined,
              text: dealer['phone'],
            ),

          // Products
          if (products.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Available Products',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6,
              children: products.map((p) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Text(p,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 20),

          // Action buttons
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: dealer['phone'] != null
                    ? () => _call(dealer['phone'])
                    : null,
                icon: const Icon(Icons.call_rounded, size: 18),
                label: const Text('Call'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final lat = (dealer['latitude'] as num?)?.toDouble();
                  final lng = (dealer['longitude'] as num?)?.toDouble();
                  if (lat != null && lng != null) _directions(lat, lng);
                },
                icon: const Icon(Icons.directions_rounded, size: 18),
                label: const Text('Directions'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _directions(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _mapCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _position != null
        ? LatLng(_position!.latitude, _position!.longitude)
        : _default;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Nearby Agro-Dealers')),
      body: Stack(children: [
        // Map
        Column(children: [
          if (widget.embedded)
            Container(
              color: AppColors.primary,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16, right: 16, bottom: 12,
              ),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text('Nearby Agro-Dealers',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                      color: Colors.white)),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition:
                        CameraPosition(target: center, zoom: 11),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    markers: _markers,
                    onMapCreated: (c) => _mapCtrl = c,
                  ),
          ),
        ]),

        // Error banner
        if (_error != null)
          Positioned(
            top: widget.embedded
                ? MediaQuery.of(context).padding.top + 60
                : 8,
            left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.95),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Showing demo dealers — enable location for nearby results.',
                    style: TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ),

        // My location FAB
        Positioned(
          bottom: 24, right: 16,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FloatingActionButton.small(
              heroTag: 'locate',
              onPressed: () {
                _mapCtrl?.animateCamera(
                    CameraUpdate.newLatLngZoom(center, 13));
              },
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              child: const Icon(Icons.my_location_rounded),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'refresh',
              onPressed: _init,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              backgroundColor: AppColors.primary,
            ),
          ]),
        ),

        // Dealer count chip
        if (!_loading && _dealers.isNotEmpty)
          Positioned(
            bottom: 24, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8)],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.store_rounded,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Text('${_dealers.length} dealers found',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String? text;
  const _InfoRow({required this.icon, this.text});

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text!,
          style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary))),
      ]),
    );
  }
}
