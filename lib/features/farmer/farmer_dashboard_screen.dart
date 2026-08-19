import 'package:flutter/material.dart';
import 'package:shambadoc/app/theme.dart';
import 'package:shambadoc/services/api/farmer_service.dart';
import 'package:shambadoc/app/routes.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});
  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  FarmerDashboard? _dashboard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    final dashboard = await FarmerService.getDashboard();
    if (mounted) {
      setState(() {
        _dashboard = dashboard;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_dashboard == null) {
      return const Scaffold(
        body: Center(child: Text('Unable to load dashboard')),
      );
    }
    final profile = _dashboard!.profile;
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(greeting,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(profile?.fullName ?? 'Farmer',
                          style: const TextStyle(fontSize: 15, color: Colors.white70)),
                      if (profile?.county != null)
                        Text(profile!.county,
                            style: const TextStyle(fontSize: 13, color: Colors.white54)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildListDelegate([
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildNearbyServices(),
            const SizedBox(height: 20),
            _buildRecentScans(),
            const SizedBox(height: 20),
            _buildAgriculturalAlerts(),
          ])),
        ),
      ]),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, Farmer';
    if (hour < 17) return 'Good afternoon, Farmer';
    return 'Good evening, Farmer';
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _QuickTile(
            icon: Icons.camera_alt_rounded, label: 'Scan Crop', color: AppColors.accent,
            onTap: () => Navigator.pushNamed(context, AppRoutes.scan),
          )),
          const SizedBox(width: 12),
          Expanded(child: _QuickTile(
            icon: Icons.search_rounded, label: 'Find Services', color: AppColors.info,
            onTap: () => Navigator.pushNamed(context, '/search'),
          )),
        ]),
      ],
    );
  }

  Widget _buildNearbyServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nearby Services', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _QuickTile(
            icon: Icons.person_rounded, label: 'Agronomists', color: AppColors.primary,
            onTap: () => Navigator.pushNamed(context, '/agronomists'),
          )),
          const SizedBox(width: 12),
          Expanded(child: _QuickTile(
            icon: Icons.store_rounded, label: 'Agrovets', color: AppColors.warning,
            onTap: () => Navigator.pushNamed(context, '/agrovets'),
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _QuickTile(
            icon: Icons.account_balance_rounded, label: 'SACCOs', color: AppColors.info,
            onTap: () => Navigator.pushNamed(context, '/saccos'),
          )),
          const SizedBox(width: 12),
          Expanded(child: _QuickTile(
            icon: Icons.shield_rounded, label: 'Insurance', color: AppColors.error,
            onTap: () => Navigator.pushNamed(context, '/insurance'),
          )),
        ]),
      ],
    );
  }

  Widget _buildRecentScans() {
    final scans = _dashboard?.recentScans ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Recent Diagnoses', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/history'),
            icon: const Icon(Icons.history_rounded, size: 18),
            label: const Text('View All'),
          ),
        ]),
        const SizedBox(height: 8),
        if (scans.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(child: Text('No scans yet. Tap Scan Crop to start.')),
          )
        else
          ...scans.map((scan) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ScanHistoryTile(scan: scan),
          )),
      ],
    );
  }

  Widget _buildAgriculturalAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Agricultural Alerts', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warning.withOpacity(0.25)),
          ),
          child: Row(children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(
              'Fall Armyworm alert reported in Kiambu County. Inspect your maize crops regularly.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            )),
          ]),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanHistoryTile extends StatelessWidget {
  final dynamic scan;

  const _ScanHistoryTile({required this.scan});

  @override
  Widget build(BuildContext context) {
    final name = scan['disease_name'] ?? 'Unknown';
    final confidence = (scan['confidence'] ?? 0) as double;
    final crop = scan['crop_type'] ?? 'Unknown';
    final time = scan['scanned_at'] != null
        ? DateTime.tryParse(scan['scanned_at']) ?? DateTime.now()
        : DateTime.now();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.eco_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text('$crop • ${(confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            '${time.day}/${time.month}/${time.year}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
