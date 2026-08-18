import 'package:shambadoc/ai/tflite_service.dart';
import 'package:flutter/material.dart';
import 'package:shambadoc/app/theme.dart';
import 'package:shambadoc/features/scan/scan_screen.dart';
import 'package:shambadoc/features/scan/result_screen.dart';
import 'package:shambadoc/features/history/history_screen.dart';
import 'package:shambadoc/features/map/agro_dealer_map.dart';
import 'package:shambadoc/features/settings/settings_screen.dart';

class AppRoutes {
  static const splash   = '/';
  static const home     = '/home';
  static const scan     = '/scan';
  static const result   = '/result';
  static const history  = '/history';
  static const map      = '/map';
  static const settings = '/settings';

  static Map<String, WidgetBuilder> getRoutes() => {
    splash:   (_) => const SplashScreen(),
    home:     (_) => const HomeScreen(),
    scan:     (_) => const ScanScreen(),
    result:   (_) => const ResultScreen(),
    history:  (_) => const HistoryScreen(),
    map:      (_) => const AgroDealerMap(),
    settings: (_) => const SettingsScreen(),
  };
}

// ── Splash ────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  late final Animation<double> _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  late final Animation<double> _scale = Tween(begin: 0.75, end: 1.0)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    await TFLiteService().init();
    if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF388E3C)],
        ),
      ),
      child: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 108, height: 108,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.eco_rounded, size: 62, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('ShambaDoc',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800,
                    color: Colors.white, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text('AI-Powered Crop Diagnosis',
                style: TextStyle(fontSize: 15,
                    color: Colors.white.withOpacity(0.8), letterSpacing: 0.4)),
              const SizedBox(height: 52),
              SizedBox(width: 28, height: 28,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white.withOpacity(0.55))),
            ]),
          ),
        ),
      ),
    ),
  );
}

// ── Home shell ────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int index = 0;

  static final List<Widget> _pages = const [
    _HomeTab(),
    HistoryScreen(embedded: true),
    AgroDealerMap(embedded: true),
    SettingsScreen(embedded: true),
  ];

  void switchTo(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: index, children: _pages),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: switchTo,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
          label: 'Home'),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history_rounded, color: AppColors.primary),
          label: 'History'),
        NavigationDestination(
          icon: Icon(Icons.store_outlined),
          selectedIcon: Icon(Icons.store_rounded, color: AppColors.primary),
          label: 'Dealers'),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
          label: 'Settings'),
      ],
    ),
  );
}

// ── Home tab ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  void _go(BuildContext context, int i) =>
      context.findAncestorStateOfType<HomeScreenState>()?.switchTo(i);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 170,
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Karibu, Mkulima! 👋',
                            style: TextStyle(fontSize: 22,
                                fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text("What's affecting your crops today?",
                            style: TextStyle(fontSize: 13,
                                color: Colors.white.withOpacity(0.8))),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle),
                        child: const Icon(Icons.eco_rounded, size: 36, color: Colors.white),
                      ),
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
            _ScanCTA(),
            const SizedBox(height: 20),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _QuickTile(
                icon: Icons.history_rounded, label: 'Scan History',
                color: AppColors.info, bg: const Color(0xFFE3F2FD),
                onTap: () => _go(context, 1))),
              const SizedBox(width: 12),
              Expanded(child: _QuickTile(
                icon: Icons.store_rounded, label: 'Agro-Dealers',
                color: AppColors.accent, bg: const Color(0xFFFFF3E0),
                onTap: () => _go(context, 2))),
            ]),
            const SizedBox(height: 20),
            Text('Tips for Better Results', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const _Tip(icon: Icons.wb_sunny_outlined,
              text: 'Photograph in natural daylight for best AI accuracy.'),
            const SizedBox(height: 8),
            const _Tip(icon: Icons.center_focus_strong_outlined,
              text: 'Focus on the most affected leaf — fill the frame.'),
            const SizedBox(height: 8),
            const _Tip(icon: Icons.wifi_off_outlined,
              text: 'Works fully offline — no internet needed for diagnosis.'),
            const SizedBox(height: 8),
            const _Tip(icon: Icons.loop_outlined,
              text: 'Low confidence? Retake in better light or use cloud analysis.'),
            SizedBox(height: w * 0.22),
          ])),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.scan),
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Scan Crop',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        backgroundColor: AppColors.accent,
      ),
    );
  }
}

class _ScanCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pushNamed(context, AppRoutes.scan),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF43A047)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Diagnose Your Crop',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800,
                  color: Colors.white)),
            const SizedBox(height: 6),
            Text('Instant AI disease detection from a photo',
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: const Text('Start Scan →',
                style: TextStyle(color: AppColors.primary,
                    fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ],
        )),
        const SizedBox(width: 8),
        const Icon(Icons.camera_alt_rounded, size: 72, color: Colors.white24),
      ]),
    ),
  );
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, bg;
  final VoidCallback onTap;
  const _QuickTile({required this.icon, required this.label,
    required this.color, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 10),
        Text(label, style: TextStyle(
            fontWeight: FontWeight.w700, color: color, fontSize: 14)),
      ]),
    ),
  );
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Tip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      border: const Border(left: BorderSide(color: AppColors.primaryLight, width: 3))),
    child: Row(children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text(text,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
    ]),
  );
}