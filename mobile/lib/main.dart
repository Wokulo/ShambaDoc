import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shambadoc/app/routes.dart';
import 'package:shambadoc/app/theme.dart';
import 'package:shambadoc/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase is optional for the MVP. Without a configured google-services.json
  // this throws; we swallow it so the offline scan flow still runs. Phone auth
  // and cloud sync only work once Firebase is configured.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase not configured, running in offline mode: $e');
  }
  await StorageService().init();
  runApp(const ShambaDocApp());
}

class ShambaDocApp extends StatelessWidget {
  const ShambaDocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShambaDoc',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('sw', 'KE'),
      ],
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.getRoutes(),
    );
  }
}
