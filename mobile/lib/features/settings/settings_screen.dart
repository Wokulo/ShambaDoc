import 'package:flutter/material.dart';
import 'package:shambadoc/services/auth_service.dart';
import 'package:shambadoc/services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'en';
  bool _offlineMode = true;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _language = StorageService().getLanguage();
      _offlineMode = StorageService().getOfflineMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language / Lugha'),
            subtitle: Text(_language == 'sw' ? 'Kiswahili' : 'English'),
            trailing: DropdownButton<String>(
              value: _language,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'sw', child: Text('Kiswahili')),
              ],
              onChanged: (val) async {
                if (val != null) {
                  await StorageService().setLanguage(val);
                  setState(() => _language = val);
                }
              },
            ),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.offline_bolt),
            title: const Text('Offline-First Mode'),
            subtitle: const Text('Use on-device AI when no internet'),
            value: _offlineMode,
            onChanged: (val) async {
              await StorageService().setOfflineMode(val);
              setState(() => _offlineMode = val);
            },
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Disease Alerts'),
            subtitle: const Text('Regional outbreak notifications (V2)'),
            value: _notifications,
            onChanged: (val) => setState(() => _notifications = val),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Phone Number'),
            subtitle: Text(AuthService().currentUser?.phoneNumber ?? 'Not logged in'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('About ShambaDoc'),
            subtitle: Text('Version 1.0 - Campus Spark 2026'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await AuthService().signOut();
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
