my phone import 'package:flutter/material.dart';
import 'package:shambadoc/features/scan/scan_screen.dart';
import 'package:shambadoc/features/scan/result_screen.dart';
import 'package:shambadoc/features/history/history_screen.dart';
import 'package:shambadoc/features/map/agro_dealer_map.dart';
import 'package:shambadoc/features/settings/settings_screen.dart';
import 'package:shambadoc/features/settings/agrovet_registration_screen.dart';
import 'package:shambadoc/features/market/register_produce_screen.dart';
import 'package:shambadoc/features/market/market_recommendations_screen.dart';

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
            const SizedBox(height: 12),
            _buildActionCard(context, icon: Icons.storefront, title: 'Register Shop',
              subtitle: 'List your agrovet on ShambaDoc', color: Colors.purple.shade50,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AgrovetRegistrationScreen(
                      baseUrl: String.fromEnvironment(
                        'SHAMBADOC_API_URL',
                        defaultValue: 'http://192.168.8.5:3000',
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 12),
            _buildActionCard(context, icon: Icons.shopping_bag, title: 'Register Produce',
              subtitle: 'List crops or livestock for sale', color: Colors.teal.shade50,
              onTap: () async {
                const baseUrl = String.fromEnvironment(
                  'SHAMBADOC_API_URL',
                  defaultValue: 'http://192.168.8.5:3000',
                );
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterProduceScreen(baseUrl: baseUrl, farmerId: 1),
                  ),
                );
                if (result != null && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MarketRecommendationsScreen(
                        baseUrl: baseUrl,
                        farmerId: 1,
                        produceItemId: result,
                      ),
                    ),
                  );
                }
              }),
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
