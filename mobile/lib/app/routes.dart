import 'package:flutter/material.dart';
import 'package:shambadoc/features/scan/scan_screen.dart';
import 'package:shambadoc/features/scan/result_screen.dart';
import 'package:shambadoc/features/history/history_screen.dart';
import 'package:shambadoc/features/map/agro_dealer_map.dart';
import 'package:shambadoc/features/settings/settings_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String scan = '/scan';
  static const String result = '/result';
  static const String history = '/history';
  static const String map = '/map';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      home: (context) => const HomeScreen(),
      scan: (context) => const ScanScreen(),
      result: (context) => const ResultScreen(),
      history: (context) => const HistoryScreen(),
      map: (context) => const AgroDealerMap(),
      settings: (context) => const SettingsScreen(),
    };
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco, size: 80, color: Colors.green.shade700),
            const SizedBox(height: 16),
            Text('ShambaDoc',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
            const SizedBox(height: 8),
            const Text('AI-Powered Crop Diagnosis', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ShambaDoc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Karibu, Mkulima!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildActionCard(context, icon: Icons.camera_alt, title: 'Scan Crop',
              subtitle: 'Take a photo to diagnose disease', color: Colors.green.shade50,
              onTap: () => Navigator.pushNamed(context, AppRoutes.scan)),
            const SizedBox(height: 12),
            _buildActionCard(context, icon: Icons.history, title: 'Scan History',
              subtitle: 'View past diagnoses & treatments', color: Colors.blue.shade50,
              onTap: () => Navigator.pushNamed(context, AppRoutes.history)),
            const SizedBox(height: 12),
            _buildActionCard(context, icon: Icons.map, title: 'Find Agro-Dealer',
              subtitle: 'Locate nearest input suppliers', color: Colors.orange.shade50,
              onTap: () => Navigator.pushNamed(context, AppRoutes.map)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required IconData icon, required String title,
    required String subtitle, required Color color, required VoidCallback onTap}) {
    return Card(elevation: 2, color: color,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.green.shade700)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
